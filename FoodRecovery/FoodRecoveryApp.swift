// FoodRecoveryApp.swift
// App entry point. Configures Firebase on launch, manages auth state, and
// provides all Firebase services to the SwiftUI environment.

import FirebaseAppCheck
import FirebaseCore
import FirebaseCrashlytics
import GoogleSignIn
import SwiftData
import SwiftUI
import TipKit

@main
struct FoodRecoveryApp: App {

    // MARK: - Firebase services (injected into environment)

    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var realtimeRouteService = RealtimeRouteService()
    @StateObject private var networkMonitor = NetworkMonitor()

    // MARK: - SwiftData container (local offline cache)

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RegionalOperation.self,
            FoodBank.self,
            FoodProvider.self,
            Restaurant.self,
            RestaurantDonation.self,
            Donation.self,
            Pickup.self,
            Delivery.self,
            PickupRoute.self,
            OperationNote.self,
        ])
        let persistentConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 1. Happy path — normal persistent store
        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            return container
        }

        // 2. Recovery — store may be corrupt after a failed schema migration.
        //    Delete the on-disk file and recreate so the user keeps a working app
        //    (local data is lost, but Firestore is the source of truth).
        let storeURL = persistentConfig.url
        try? FileManager.default.removeItem(at: storeURL)
        Crashlytics.crashlytics().log("SwiftData store deleted and recreated after load failure at \(storeURL)")

        if let container = try? ModelContainer(for: schema, configurations: [persistentConfig]) {
            return container
        }

        // 3. Last resort — in-memory store so the app stays alive.
        //    Data won't persist across launches, but nothing crashes.
        Crashlytics.crashlytics().log("SwiftData falling back to in-memory store")
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        ])
    }()

    // MARK: - Initializer: configure Firebase before any service is instantiated

    init() {
        configureFirebase()
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(realtimeRouteService)
                .environmentObject(networkMonitor)
                .task {
                    await NotificationService.shared.requestPermission()
                    // Fetch Remote Config early so model-name overrides are active
                    // before the first AI call. Non-blocking — defaults serve until done.
                    await RemoteConfigService.shared.fetchAndActivate()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Firebase setup

    private func configureFirebase() {
        // AppCheck — use DeviceCheck in release, debug provider in debug builds
        #if DEBUG
        let appCheckFactory = AppCheckDebugProviderFactory()
        #else
        let appCheckFactory = DeviceCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(appCheckFactory)

        // Load the plist explicitly because the file is named GoogleService-Info-2.plist
        // rather than the default GoogleService-Info.plist.
        if let path = Bundle.main.path(forResource: "GoogleService-Info-2", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
        } else {
            // Fall back to the conventional name if the bundle is set up differently.
            FirebaseApp.configure()
        }

        // Configure Google Sign-In using the OAuth client ID from Firebase.
        if let clientID = FirebaseApp.app()?.options.clientID {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }

        // Crashlytics is active automatically after configure().
        // In debug builds, collection is opt-in; in release it is on by default.
        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif

        // In-App Messaging is enabled automatically; no additional setup needed.
    }
}

// MARK: - Root view: auth gate

private struct RootView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var firestoreService: FirestoreService

    var body: some View {
        Group {
            if authService.isSignedIn {
                ContentView()
                    .onChange(of: authService.userProfile?.operationId) { _, operationId in
                        if let operationId {
                            firestoreService.startListeningToOperation(operationId)
                        }
                    }
                    .onAppear {
                        firestoreService.startListening()
                        if let operationId = authService.userProfile?.operationId {
                            firestoreService.startListeningToOperation(operationId)
                        }
                        if let userId = authService.userId {
                            FirebaseAnalyticsService.shared.setUser(id: userId)
                        }
                    }
                    .onDisappear {
                        firestoreService.stopListening()
                    }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isSignedIn)
    }
}
