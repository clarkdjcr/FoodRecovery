//
//  Delivery.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation
import SwiftData

enum DeliveryStatus: String, CaseIterable, Codable {
  case proposed = "proposed"
  case confirmed = "confirmed"
  case inProgress = "in_progress"
  case completed = "completed"
  case cancelled = "cancelled"
}

@Model
final class Delivery {
  var id: UUID
  var scheduledTime: Date
  var actualTime: Date?
  var status: DeliveryStatus
  var notes: String
  var sortOrder: Int = 0
  var createdAt: Date
  var confirmedAt: Date?
  var completedAt: Date?
  var proofOfDeliveryPhoto: Data?

  // Relationships
  @Relationship var foodBank: FoodBank?
  @Relationship var pickupRoute: PickupRoute?
  @Relationship(deleteRule: .cascade) var donations: [Donation] = []

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
