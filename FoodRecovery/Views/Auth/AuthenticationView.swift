// AuthenticationView.swift
// Sign-in / sign-up gate shown when no Firebase user is authenticated.

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var showResetAlert = false
    @State private var resetEmail = ""

    enum AuthMode { case signIn, signUp }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                formCard
                modeToggle
                Divider().padding(.horizontal)
                anonymousButton
            }
            .padding()
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .alert("Reset Password", isPresented: $showResetAlert) {
            TextField("Email", text: $resetEmail)
            Button("Send Reset Link") {
                Task { await authService.sendPasswordReset(email: resetEmail) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email to receive a password reset link.")
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("Food Recovery")
                .font(.largeTitle).fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Connecting surplus food with communities in need")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
    }

    private var formCard: some View {
        VStack(spacing: 20) {
            Text(mode == .signIn ? "Sign In" : "Create Account")
                .font(.title2).fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if mode == .signUp {
                ModernTextField(
                    title: "Display Name",
                    placeholder: "Your name or organisation",
                    text: $displayName
                )
            }

            ModernTextField(
                title: "Email",
                placeholder: "operator@example.com",
                text: $email
            )

            AuthSecureField(title: "Password", placeholder: "••••••••", text: $password)

            if mode == .signUp {
                AuthSecureField(title: "Confirm Password", placeholder: "••••••••", text: $confirmPassword)
            }

            if let error = authService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: primaryAction) {
                Group {
                    if authService.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authService.isLoading || !formIsValid)

            if mode == .signIn {
                Button("Forgot password?") {
                    resetEmail = email
                    showResetAlert = true
                }
                .font(.caption)
                .foregroundColor(.green)
            }
        }
        .padding(24)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var modeToggle: some View {
        HStack {
            Text(mode == .signIn ? "Don't have an account?" : "Already have an account?")
                .foregroundColor(AppTheme.Colors.textSecondary)
            Button(mode == .signIn ? "Sign Up" : "Sign In") {
                withAnimation { mode = mode == .signIn ? .signUp : .signIn }
                authService.errorMessage = nil
            }
            .foregroundColor(.green)
            .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private var anonymousButton: some View {
        Button(action: {
            Task { await authService.signInAnonymously() }
        }) {
            HStack {
                Image(systemName: "person.crop.circle.badge.questionmark")
                Text("Continue as Guest")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.secondary.opacity(0.1))
            .foregroundColor(AppTheme.Colors.textSecondary)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions & validation

    private var formIsValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if mode == .signIn {
            return emailOK && passwordOK
        } else {
            return emailOK && passwordOK && !displayName.isEmpty && password == confirmPassword
        }
    }

    private func primaryAction() {
        Task {
            if mode == .signIn {
                await authService.signIn(email: email, password: password)
                FirebaseAnalyticsService.shared.log(.userSignedIn(method: "email"))
            } else {
                await authService.signUp(email: email, password: password, displayName: displayName)
                FirebaseAnalyticsService.shared.log(.userSignedUp)
            }
        }
    }
}

// MARK: - Styled secure field matching ModernTextField appearance

private struct AuthSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.textPrimary)

            SecureField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(.plain)
                .foregroundColor(Color(white: 0.1))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isFocused ? Color.blue : Color.gray.opacity(0.3),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(FirebaseAuthService())
}
