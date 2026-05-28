//
//  Donation.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation
import SwiftData

enum DonationStatus: String, CaseIterable, Codable {
  case pending = "pending"
  case confirmed = "confirmed"
  case scheduled = "scheduled"
  case pickedUp = "picked_up"
  case delivered = "delivered"
  case cancelled = "cancelled"
}

enum FoodType: String, CaseIterable, Codable {
  case produce = "produce"
  case dairy = "dairy"
  case meat = "meat"
  case bakery = "bakery"
  case frozen = "frozen"
  case canned = "canned"
  case prepared = "prepared"
  case other = "other"
}

@Model
final class Donation {
  var id: UUID
  var foodType: FoodType
  var quantity: Double  // in pounds
  var expirationDate: Date?
  var foodDescription: String
  var status: DonationStatus
  var createdAt: Date
  var emailSource: String  // Original email address
  var emailSubject: String
  var emailBody: String
  var aiExtractedData: String  // JSON string of AI extraction results
  var aiConfidence: Double  // Confidence level of AI extraction (0.0 to 1.0)
  var isVerified: Bool  // Whether the donation has been human-verified
  var carbonOffset: Double  // Estimated CO2 offset in kg

  // Relationships
  @Relationship var foodProvider: FoodProvider?
  @Relationship var pickup: Pickup?
  @Relationship var delivery: Delivery?

  init(
    foodType: FoodType, quantity: Double, expirationDate: Date? = nil, description: String,
    emailSource: String, emailSubject: String, emailBody: String, aiExtractedData: String = "",
    aiConfidence: Double = 1.0, isVerified: Bool = false
  ) {
    self.id = UUID()
    self.foodType = foodType
    self.quantity = quantity
    self.expirationDate = expirationDate
    self.foodDescription = description
    self.status = .pending
    self.createdAt = Date()
    self.emailSource = emailSource
    self.emailSubject = emailSubject
    self.emailBody = emailBody
    self.aiExtractedData = aiExtractedData
    self.aiConfidence = aiConfidence
    self.isVerified = isVerified
    
    // Calculate carbon offset (simplified: avg 2.8kg CO2 per lb for meat, 0.5kg for produce)
    let factor: Double
    switch foodType {
    case .meat: factor = 2.8
    case .dairy: factor = 1.2
    case .produce: factor = 0.4
    case .bakery: factor = 0.6
    default: factor = 0.8
    }
    self.carbonOffset = quantity * factor
  }

  var isExpired: Bool {
    guard let expirationDate = expirationDate else { return false }
    return expirationDate < Date()
  }

  var daysUntilExpiration: Int? {
    guard let expirationDate = expirationDate else { return nil }
    let calendar = Calendar.current
    return calendar.dateComponents([.day], from: Date(), to: expirationDate).day
  }
}
