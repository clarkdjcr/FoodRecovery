//
//  SettingsView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @State private var smtpUsername = ""
    @State private var smtpPassword = ""
    @State private var showSavedBanner = false

    var body: some View {
        Form {
            Section {
                Label("Firebase-managed AI", systemImage: "flame.fill")
                    .foregroundColor(.orange)
                Text("Donation emails are processed through Firebase. Provider secrets are stored server-side in Firebase Secrets and are never entered or stored on this device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("AI Processing")
            } footer: {
                Text("Current model configuration is delivered through Firebase Remote Config. API keys are not exposed in the iOS app.")
            }

            Section {
                TextField("Gmail Address", text: $smtpUsername)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                SecureField("App Password", text: $smtpPassword)
                    .textContentType(.password)
                    .autocorrectionDisabled()
            } header: {
                Text("Email (SMTP)")
            } footer: {
                Text("Use a Gmail App Password, not your account password. Generate one at myaccount.google.com/apppasswords.")
            }

            Section {
                Button("Save Credentials") {
                    saveCredentials()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            if showSavedBanner {
                Section {
                    Label("Email credentials saved securely to Keychain", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)
                }
            }

            Section {
                Button("Clear Email Credentials", role: .destructive) {
                    clearCredentials()
                }
            } footer: {
                Text("Removes stored SMTP credentials from the device Keychain.")
            }

            // MARK: - Firebase Account section
            Section {
                HStack {
                    Image(systemName: authService.isAnonymous
                          ? "person.crop.circle.badge.questionmark"
                          : "person.crop.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.displayName)
                            .fontWeight(.medium)
                        Text(authService.isAnonymous ? "Guest Account" : authService.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Firebase Account")
            } footer: {
                Text("Authenticated via Firebase Auth. Your data syncs to Firestore across devices.")
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadCredentials)
    }

    private func loadCredentials() {
        smtpUsername = KeychainService.retrieve(forKey: AppConfiguration.smtpUsernameKeyName) ?? ""
        smtpPassword = KeychainService.retrieve(forKey: AppConfiguration.smtpPasswordKeyName) ?? ""
    }

    private func saveCredentials() {
        KeychainService.save(smtpUsername, forKey: AppConfiguration.smtpUsernameKeyName)
        KeychainService.save(smtpPassword, forKey: AppConfiguration.smtpPasswordKeyName)
        withAnimation {
            showSavedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showSavedBanner = false }
        }
    }

    private func clearCredentials() {
        KeychainService.delete(forKey: AppConfiguration.aiProviderKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpUsernameKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpPasswordKeyName)
        smtpUsername = ""
        smtpPassword = ""
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
