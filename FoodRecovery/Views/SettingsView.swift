//
//  SettingsView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: FirebaseAuthService
    @State private var selectedProvider: AIProvider = .openAI
    @State private var openAIKey = ""
    @State private var anthropicKey = ""
    @State private var geminiKey = ""
    @State private var smtpUsername = ""
    @State private var smtpPassword = ""
    @State private var showSavedBanner = false

    var body: some View {
        Form {
            Section {
                Picker("AI Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Selects which AI service processes donation emails. The active provider's key must be set below.")
            }

            switch selectedProvider {
            case .openAI:
                Section {
                    SecureField("API Key", text: $openAIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("OpenAI")
                } footer: {
                    Text("Get a key at platform.openai.com. Model: \(AppConfiguration.openAIModel).")
                }
            case .anthropic:
                Section {
                    SecureField("API Key", text: $anthropicKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("Anthropic (Claude)")
                } footer: {
                    Text("Get a key at console.anthropic.com. Model: \(AppConfiguration.anthropicModel).")
                }
            case .gemini:
                Section {
                    Label("Powered by Firebase AI", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                    Text("No API key required — authentication is handled automatically through Firebase.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Divider()
                    Text("Optional direct key (fallback only):")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("Gemini API Key (optional)", text: $geminiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("Google Gemini via Firebase AI")
                } footer: {
                    Text("Uses Firebase AI SDK (Gemini \(AppConfiguration.geminiModel)) with AppCheck security. An optional direct key serves as a fallback.")
                }
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
                    Label("Credentials saved securely to Keychain", systemImage: "checkmark.shield.fill")
                        .foregroundColor(.green)
                }
            }

            Section {
                Button("Clear All Credentials", role: .destructive) {
                    clearCredentials()
                }
            } footer: {
                Text("Removes all stored credentials from the device Keychain.")
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
        let providerRaw = KeychainService.retrieve(forKey: AppConfiguration.aiProviderKeyName) ?? AIProvider.openAI.rawValue
        selectedProvider = AIProvider(rawValue: providerRaw) ?? .openAI
        openAIKey = KeychainService.retrieve(forKey: AppConfiguration.openAIKeyName) ?? ""
        anthropicKey = KeychainService.retrieve(forKey: AppConfiguration.anthropicKeyName) ?? ""
        geminiKey = KeychainService.retrieve(forKey: AppConfiguration.geminiKeyName) ?? ""
        smtpUsername = KeychainService.retrieve(forKey: AppConfiguration.smtpUsernameKeyName) ?? ""
        smtpPassword = KeychainService.retrieve(forKey: AppConfiguration.smtpPasswordKeyName) ?? ""
    }

    private func saveCredentials() {
        KeychainService.save(selectedProvider.rawValue, forKey: AppConfiguration.aiProviderKeyName)
        KeychainService.save(openAIKey, forKey: AppConfiguration.openAIKeyName)
        KeychainService.save(anthropicKey, forKey: AppConfiguration.anthropicKeyName)
        KeychainService.save(geminiKey, forKey: AppConfiguration.geminiKeyName)
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
        KeychainService.delete(forKey: AppConfiguration.openAIKeyName)
        KeychainService.delete(forKey: AppConfiguration.anthropicKeyName)
        KeychainService.delete(forKey: AppConfiguration.geminiKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpUsernameKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpPasswordKeyName)
        selectedProvider = .openAI
        openAIKey = ""
        anthropicKey = ""
        geminiKey = ""
        smtpUsername = ""
        smtpPassword = ""
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
