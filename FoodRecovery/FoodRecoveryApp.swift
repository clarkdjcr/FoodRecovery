// FoodRecoveryApp.swift
// App entry point. Configures Firebase on launch, manages auth state, and
// provides all Firebase services to the SwiftUI environment.

import FirebaseAppCheck
import FirebaseCore
import FirebaseCrashlytics
import SwiftData
import SwiftUI

@main
struct FoodRecoveryApp: App {

    // MARK: - Firebase services (injected into environment)

    @StateObject private var authService = FirebaseAuthService()
    @StateObject private var firestoreService = FirestoreService()
    @StateObject private var realtimeRouteService = RealtimeRouteService()

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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Initializer: configure Firebase before any service is instantiated

    init() {
        configureFirebase()
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(firestoreService)
                .environmentObject(realtimeRouteService)
                .task {
                    await NotificationService.shared.requestPermission()
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
