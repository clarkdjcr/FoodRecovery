// FirebaseAuthService.swift
// Manages Firebase Authentication state throughout the app.
// Supports email/password, Google Sign-In, and anonymous sign-in.

import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import GoogleSignIn

@MainActor
final class FirebaseAuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var userProfile: UserProfileDocument?
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var stateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

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

    // MARK: - Email / Password

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

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            let signInResult = try await performGoogleSignIn()
            guard let idToken = signInResult.user.idToken?.tokenString else {
                errorMessage = "Google Sign-In failed: missing ID token."
                isLoading = false
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: signInResult.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            if userProfile == nil {
                await createUserProfile(
                    uid: authResult.user.uid,
                    email: authResult.user.email ?? "",
                    displayName: authResult.user.displayName ?? ""
                )
            }
            FirebaseAnalyticsService.shared.log(.userSignedIn(method: "google"))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Apple Sign-In
    // Split across two methods so SignInWithAppleButton can own the ASAuthorization
    // presentation while the service owns the Firebase credential exchange.

    // Called in SignInWithAppleButton's onRequest closure. Returns the SHA-256
    // hashed nonce to embed in the ASAuthorizationAppleIDRequest.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // Called in SignInWithAppleButton's onCompletion closure.
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer {
            currentNonce = nil
            isLoading = false
        }
        do {
            let authorization = try result.get()
            guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleCredential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8),
                  let rawNonce = currentNonce else {
                errorMessage = "Apple Sign-In failed: invalid credential."
                return
            }
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: rawNonce,
                fullName: appleCredential.fullName
            )
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            if userProfile == nil {
                let name = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                await createUserProfile(
                    uid: authResult.user.uid,
                    email: authResult.user.email ?? appleCredential.email ?? "",
                    displayName: name.isEmpty ? "Apple User" : name
                )
            }
            FirebaseAnalyticsService.shared.log(.userSignedIn(method: "apple"))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Anonymous

    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().signInAnonymously()
            await createUserProfile(uid: result.user.uid, email: "", displayName: "Anonymous Operator")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Password reset

    func sendPasswordReset(email: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - User profile helpers

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

    // MARK: - Private

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
            // Profile may not exist yet on first login; silently ignore
        }
    }

    // MARK: - Nonce helpers (required for Apple Sign-In security)

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }

    // Wraps GIDSignIn's callback API in async/await and handles iOS vs macOS presentation.
    private func performGoogleSignIn() async throws -> GIDSignInResult {
        try await withCheckedThrowingContinuation { continuation in
#if os(iOS)
            guard let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
                continuation.resume(throwing: GoogleSignInError.noPresentingWindow)
                return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: root) { result, error in
                if let error { continuation.resume(throwing: error); return }
                guard let result else {
                    continuation.resume(throwing: GoogleSignInError.unknownResult); return
                }
                continuation.resume(returning: result)
            }
#else
            guard let window = NSApplication.shared.keyWindow
                              ?? NSApplication.shared.windows.first else {
                continuation.resume(throwing: GoogleSignInError.noPresentingWindow)
                return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
                if let error { continuation.resume(throwing: error); return }
                guard let result else {
                    continuation.resume(throwing: GoogleSignInError.unknownResult); return
                }
                continuation.resume(returning: result)
            }
#endif
        }
    }
}

// MARK: - Errors

private enum GoogleSignInError: LocalizedError {
    case noPresentingWindow
    case unknownResult

    var errorDescription: String? {
        switch self {
        case .noPresentingWindow: return "Cannot find a window to present the Google Sign-In sheet."
        case .unknownResult: return "Google Sign-In returned an unexpected result."
        }
    }
}
