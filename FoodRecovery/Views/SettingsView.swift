//
//  SettingsView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var openAIKey = ""
    @State private var smtpUsername = ""
    @State private var smtpPassword = ""
    @State private var showSavedBanner = false

    var body: some View {
        Form {
            Section {
                SecureField("API Key", text: $openAIKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
            } header: {
                Text("OpenAI")
            } footer: {
                Text("Used for intelligent donation email extraction. Get a key at platform.openai.com.")
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
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadCredentials)
    }

    private func loadCredentials() {
        openAIKey = KeychainService.retrieve(forKey: AppConfiguration.openAIKeyName) ?? ""
        smtpUsername = KeychainService.retrieve(forKey: AppConfiguration.smtpUsernameKeyName) ?? ""
        smtpPassword = KeychainService.retrieve(forKey: AppConfiguration.smtpPasswordKeyName) ?? ""
    }

    private func saveCredentials() {
        KeychainService.save(openAIKey, forKey: AppConfiguration.openAIKeyName)
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
        KeychainService.delete(forKey: AppConfiguration.openAIKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpUsernameKeyName)
        KeychainService.delete(forKey: AppConfiguration.smtpPasswordKeyName)
        openAIKey = ""
        smtpUsername = ""
        smtpPassword = ""
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
