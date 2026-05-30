//
//  AppConfiguration.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

enum AIProvider: String, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"
    case gemini = "gemini"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI (GPT-4o)"
        case .anthropic: return "Anthropic (Claude)"
        case .gemini: return "Google Gemini"
        }
    }
}

struct AppConfiguration {
    // Keychain key names
    static let openAIKeyName = "openai_api_key"
    static let anthropicKeyName = "anthropic_api_key"
    static let geminiKeyName = "gemini_api_key"
    static let aiProviderKeyName = "ai_provider"
    static let smtpUsernameKeyName = "smtp_username"
    static let smtpPasswordKeyName = "smtp_password"

    // AI provider selection
    static var activeAIProvider: AIProvider {
        let raw = KeychainService.retrieve(forKey: aiProviderKeyName) ?? AIProvider.openAI.rawValue
        return AIProvider(rawValue: raw) ?? .openAI
    }

    // OpenAI Configuration — key from Keychain, model name from Remote Config (falls back to default)
    static var openAIAPIKey: String { KeychainService.retrieve(forKey: openAIKeyName) ?? "" }
    static let defaultOpenAIModel = "gpt-4o-mini"
    @MainActor static var openAIModel: String { RemoteConfigService.shared.openAIModel }

    // Anthropic Configuration
    static var anthropicAPIKey: String { KeychainService.retrieve(forKey: anthropicKeyName) ?? "" }
    static let defaultAnthropicModel = "claude-sonnet-4-6"
    @MainActor static var anthropicModel: String { RemoteConfigService.shared.anthropicModel }

    // Google Gemini Configuration — key optional; Firebase AI uses App Check instead
    static var geminiAPIKey: String { KeychainService.retrieve(forKey: geminiKeyName) ?? "" }
    static let defaultGeminiModel = "gemini-2.0-flash"
    @MainActor static var geminiModel: String { RemoteConfigService.shared.geminiModel }

    // Email Configuration — port 465 = SMTPS (TLS on connect, no STARTTLS needed)
    static let smtpHost = "smtp.gmail.com"
    static let smtpPort = 465
    static var smtpUsername: String { KeychainService.retrieve(forKey: smtpUsernameKeyName) ?? "" }
    static var smtpPassword: String { KeychainService.retrieve(forKey: smtpPasswordKeyName) ?? "" }

    // Route Optimization Configuration
    static let averageSpeedMPH = 30.0
    static let stopTimeMinutes = 15.0
    static let maxRouteDurationHours = 4.0

    // Default Values
    static let defaultServiceRadiusMiles = 35.0
    static let defaultMaxFoodBanks = 5
    static let defaultOperatingHours = "8:00 AM - 6:00 PM"

    // Validation Rules
    static let minServiceRadiusMiles = 10.0
    static let maxServiceRadiusMiles = 50.0
    static let minFoodBankCapacity = 100
    static let maxFoodBankCapacity = 5000
}
