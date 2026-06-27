// RemoteConfigService.swift
// Fetches non-secret app configuration from Firebase Remote Config.
//
// SECURITY MODEL:
//   1. Non-secret app config   -> Firebase Remote Config + App Check (this file)
//   2. App-owned API keys      -> Firebase Secrets / Google Cloud Secret Manager;
//                                the client never sees provider credentials.
//
// Remote Config values are NOT secret — they are cached on-device after fetch.
// Use them for model names, feature flags, and rate limits, NOT for private keys.
//
// SETUP: Add FirebaseRemoteConfig to the target in Xcode:
//   Target → Frameworks, Libraries → "+" → FirebaseRemoteConfig (firebase-ios-sdk)

import FirebaseRemoteConfig
import Foundation

@MainActor
final class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()

    private let rc = RemoteConfig.remoteConfig()

    // Published so views can react if needed
    @Published private(set) var isActivated = false

    private init() {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3_600  // 1 hour
        #endif
        rc.configSettings = settings

        // In-app defaults — used until a fetch succeeds.
        rc.setDefaults([
            RemoteConfigKey.openAIModel.rawValue:    AppConfiguration.defaultOpenAIModel    as NSObject,
            RemoteConfigKey.anthropicModel.rawValue: AppConfiguration.defaultAnthropicModel as NSObject,
            RemoteConfigKey.geminiModel.rawValue:    AppConfiguration.defaultGeminiModel    as NSObject,
            RemoteConfigKey.aiEnabled.rawValue:      true                                   as NSObject,
            RemoteConfigKey.maxEmailsPerSession.rawValue: 20                                as NSObject,
        ])
    }

    // Call once on app launch (FoodRecoveryApp.init or onAppear of RootView).
    func fetchAndActivate() async {
        do {
            let status = try await rc.fetchAndActivate()
            isActivated = status != .error
        } catch {
            // Non-fatal: defaults remain active. Crashlytics breadcrumb only.
            print("RemoteConfig fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Typed accessors

    var openAIModel: String    { rc[RemoteConfigKey.openAIModel.rawValue].stringValue }
    var anthropicModel: String { rc[RemoteConfigKey.anthropicModel.rawValue].stringValue }
    var geminiModel: String    { rc[RemoteConfigKey.geminiModel.rawValue].stringValue }
    var aiEnabled: Bool        { rc[RemoteConfigKey.aiEnabled.rawValue].boolValue }
    var maxEmailsPerSession: Int {
        rc[RemoteConfigKey.maxEmailsPerSession.rawValue].numberValue.intValue
    }
}

// MARK: - Key registry — prevents typo bugs in raw string keys

private enum RemoteConfigKey: String {
    case openAIModel            = "openai_model"
    case anthropicModel         = "anthropic_model"
    case geminiModel            = "gemini_model"
    case aiEnabled              = "ai_enabled"
    case maxEmailsPerSession    = "max_emails_per_session"
}
