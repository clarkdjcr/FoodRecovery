//
//  FoodBank.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class FoodBank {
  var id: UUID
  var name: String
  var address: String
  var latitude: Double?
  var longitude: Double?
  var capacity: Int  // Daily capacity in pounds
  var dailyUsage: Int  // Current daily usage in pounds
  var contactName: String
  var contactEmail: String
  var contactPhone: String
  var operatingHours: String
  var specialRequirements: String
  var priorityNeeds: [FoodType]
  var isActive: Bool
  var createdAt: Date
  var lastDelivery: Date?

  // Relationships
  @Relationship var regionalOperation: RegionalOperation?
  @Relationship(deleteRule: .cascade) var deliveries: [Delivery] = []

  init(
    name: String, address: String, latitude: Double?, longitude: Double?, capacity: Int, dailyUsage: Int,
    contactName: String, contactEmail: String, contactPhone: String, operatingHours: String,
    specialRequirements: String = "",
    priorityNeeds: [FoodType] = []
  ) {
    self.id = UUID()
    self.name = name
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
    self.capacity = capacity
    self.dailyUsage = dailyUsage
    self.contactName = contactName
    self.contactEmail = contactEmail
    self.contactPhone = contactPhone
    self.operatingHours = operatingHours
    self.specialRequirements = specialRequirements
    self.priorityNeeds = priorityNeeds
    self.isActive = true
    self.createdAt = Date()
  }

  var availableCapacity: Int {
    return capacity - dailyUsage
  }

  var utilizationPercentage: Double {
    guard capacity > 0 else { return 0 }
    return Double(dailyUsage) / Double(capacity) * 100
  }
}
