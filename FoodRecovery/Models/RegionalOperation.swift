//
//  RegionalOperation.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class RegionalOperation {
  var id: UUID
  var name: String
  var regionCenterLatitude: Double
  var regionCenterLongitude: Double
  var radiusMiles: Double
  var maxFoodBanks: Int
  var operationHours: String
  var contactEmail: String
  var contactPhone: String
  var numberOfTrucks: Int
  var createdAt: Date
  var isActive: Bool

  // Relationships
  @Relationship(deleteRule: .cascade) var foodBanks: [FoodBank] = []
  @Relationship(deleteRule: .cascade) var groceryStores: [GroceryStore] = []
  @Relationship(deleteRule: .cascade) var restaurants: [Restaurant] = []
  @Relationship(deleteRule: .cascade) var pickupRoutes: [PickupRoute] = []

  init(
    name: String, regionCenter: CLLocationCoordinate2D, radiusMiles: Double = 35.0,
    maxFoodBanks: Int = 5, numberOfTrucks: Int = 1, operationHours: String, contactEmail: String, contactPhone: String
  ) {
    self.id = UUID()
    self.name = name
    self.regionCenterLatitude = regionCenter.latitude
    self.regionCenterLongitude = regionCenter.longitude
    self.radiusMiles = radiusMiles
    self.maxFoodBanks = maxFoodBanks
    self.numberOfTrucks = numberOfTrucks
    self.operationHours = operationHours
    self.contactEmail = contactEmail
    self.contactPhone = contactPhone
    self.createdAt = Date()
    self.isActive = true
  }
  
  var regionCenter: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: regionCenterLatitude, longitude: regionCenterLongitude)
  }
}
