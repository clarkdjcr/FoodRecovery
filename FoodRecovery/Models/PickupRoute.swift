//
//  PickupRoute.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

enum RouteStatus: String, CaseIterable, Codable {
  case planned = "planned"
  case active = "active"
  case completed = "completed"
  case cancelled = "cancelled"
}

@Model
final class PickupRoute {
  var id: UUID
  var date: Date
  var startTime: Date
  var endTime: Date
  var status: RouteStatus
  var totalDistance: Double  // in miles
  var estimatedDuration: TimeInterval  // in seconds
  var actualDuration: TimeInterval?
  var notes: String
  var createdAt: Date
  var completedAt: Date?
  var currentStopIndex: Int = 0
  var vehicleId: String?

  // Relationships
  @Relationship var regionalOperation: RegionalOperation?
  @Relationship(deleteRule: .cascade) var pickups: [Pickup] = []
  @Relationship(deleteRule: .cascade) var deliveries: [Delivery] = []

  init(date: Date, startTime: Date, endTime: Date, notes: String = "") {
    self.id = UUID()
    self.date = date
    self.startTime = startTime
    self.endTime = endTime
    self.status = .planned
    self.totalDistance = 0.0
    self.estimatedDuration = 0.0
    self.actualDuration = nil
    self.notes = notes
    self.createdAt = Date()
    self.completedAt = nil
  }

  var totalPickupQuantity: Double {
    return pickups.reduce(0) { $0 + $1.totalQuantity }
  }

  var totalDeliveryQuantity: Double {
    return deliveries.reduce(0) { $0 + $1.totalQuantity }
  }

  var isActive: Bool {
    let now = Date()
    return status == .active && now >= startTime && now <= endTime
  }

  var isOverdue: Bool {
    return status == .planned && startTime < Date()
  }
}
