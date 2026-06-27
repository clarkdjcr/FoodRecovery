//
//  Pickup.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation
import SwiftData

enum PickupStatus: String, CaseIterable, Codable {
  case proposed = "proposed"
  case confirmed = "confirmed"
  case inProgress = "in_progress"
  case completed = "completed"
  case cancelled = "cancelled"
}

@Model
final class Pickup {
  var id: UUID
  var scheduledTime: Date
  var actualTime: Date?
  var status: PickupStatus
  var notes: String
  var sortOrder: Int = 0
  var createdAt: Date
  var confirmedAt: Date?
  var completedAt: Date?
  var proofOfPickupPhoto: Data?

  // Relationships
  @Relationship var foodProvider: FoodProvider?
  @Relationship var restaurant: Restaurant?
  @Relationship var pickupRoute: PickupRoute?
  @Relationship(deleteRule: .cascade) var donations: [Donation] = []
  @Relationship(deleteRule: .cascade) var restaurantDonations: [RestaurantDonation] = []

  init(scheduledTime: Date, notes: String = "") {
    self.id = UUID()
    self.scheduledTime = scheduledTime
    self.status = .proposed
    self.notes = notes
    self.createdAt = Date()
  }

  var totalQuantity: Double {
    return donations.reduce(0) { $0 + $1.quantity }
  }

  var isOverdue: Bool {
    return status == .proposed && scheduledTime < Date()
  }
}
