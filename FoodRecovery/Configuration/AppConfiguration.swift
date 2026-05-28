//
//  AppConfiguration.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

struct AppConfiguration {
    // Keychain key names
    static let openAIKeyName = "openai_api_key"
    static let smtpUsernameKeyName = "smtp_username"
    static let smtpPasswordKeyName = "smtp_password"

    // OpenAI Configuration — loaded from Keychain at runtime
    static var openAIAPIKey: String { KeychainService.retrieve(forKey: openAIKeyName) ?? "" }
    static let openAIModel = "gpt-4o-mini"

    // Email Configuration — host/port are not secrets
    static let smtpHost = "smtp.gmail.com"
    static let smtpPort = 587
    static var smtpUsername: String { KeychainService.retrieve(forKey: smtpUsernameKeyName) ?? "" }
    static var smtpPassword: String { KeychainService.retrieve(forKey: smtpPasswordKeyName) ?? "" }
    static let defaultToEmail = ""

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
