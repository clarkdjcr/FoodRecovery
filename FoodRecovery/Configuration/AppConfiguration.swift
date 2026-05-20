//
//  AppConfiguration.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

struct AppConfiguration {
  // OpenAI Configuration (set via environment or user settings before use)
  static let openAIAPIKey = ""
  static let openAIModel = "gpt-4"

  // Email Configuration (configure before use)
  static let smtpHost = "smtp.gmail.com"
  static let smtpPort = 587
  static let smtpUsername = ""
  static let smtpPassword = ""
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
