// FirebaseAuthService.swift
// Manages Firebase Authentication state throughout the app.
// Supports email/password accounts and anonymous sign-in for quick access.

import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
final class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var userProfile: UserProfileDocument?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var stateHandle: AuthStateDidChangeListenerHandle?

    init() {
        stateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                self?.currentUser = user
                self?.isSignedIn = user != nil
                if let user = user {
                    await self?.fetchUserProfile(uid: user.uid)
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }

    deinit {
        if let handle = stateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth operations

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            await createUserProfile(uid: result.user.uid, email: email, displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signInAnonymously()
            let displayName = "Anonymous Operator"
            await createUserProfile(uid: result.user.uid, email: "", displayName: displayName)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - User profile

    private func createUserProfile(uid: String, email: String, displayName: String) async {
        let profile = UserProfileDocument.makeNew(uid: uid, email: email, displayName: displayName)
        do {
            try db.collection("users").document(uid).setData(from: profile)
            userProfile = profile
        } catch {
            errorMessage = "Failed to create user profile: \(error.localizedDescription)"
        }
    }

    private func fetchUserProfile(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            userProfile = try doc.data(as: UserProfileDocument.self)
        } catch {
            // Profile may not exist yet for the first login; silently ignore
        }
    }

    func linkOperationToUser(operationId: String) async {
        guard let uid = currentUser?.uid else { return }
        do {
            try await db.collection("users").document(uid).updateData(["operationId": operationId])
            userProfile?.operationId = operationId
        } catch {
            errorMessage = "Failed to link operation: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed helpers

    var displayName: String {
        currentUser?.displayName ?? currentUser?.email ?? "Operator"
    }

    var isAnonymous: Bool {
        currentUser?.isAnonymous ?? false
    }

    var userId: String? {
        currentUser?.uid
    }
}
