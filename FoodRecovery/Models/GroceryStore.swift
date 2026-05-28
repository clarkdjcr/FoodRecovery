//
//  GroceryStore.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class FoodProvider {
  var id: UUID
  var name: String
  var address: String
  var latitude: Double?
  var longitude: Double?
  var contactName: String
  var contactEmail: String
  var contactPhone: String
  var donationEmail: String  // Email address for receiving donation notifications
  var operatingHours: String
  var preferredPickupTimes: String
  var isActive: Bool
  var createdAt: Date
  var lastPickup: Date?

  // Relationships
  @Relationship var regionalOperation: RegionalOperation?
  @Relationship(deleteRule: .cascade) var donations: [Donation] = []
  @Relationship(deleteRule: .cascade) var pickups: [Pickup] = []

  init(
    name: String, address: String, latitude: Double?, longitude: Double?, contactName: String,
    contactEmail: String, contactPhone: String, donationEmail: String, operatingHours: String,
    preferredPickupTimes: String = ""
  ) {
    self.id = UUID()
    self.name = name
    self.address = address
    self.latitude = latitude
    self.longitude = longitude
    self.contactName = contactName
    self.contactEmail = contactEmail
    self.contactPhone = contactPhone
    self.donationEmail = donationEmail
    self.operatingHours = operatingHours
    self.preferredPickupTimes = preferredPickupTimes
    self.isActive = true
    self.createdAt = Date()
  }
}
