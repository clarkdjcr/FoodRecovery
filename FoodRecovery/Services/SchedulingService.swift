//
//  SchedulingService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

class SchedulingService {
  private let routeOptimizer = RouteOptimizationService()

  func generatePickupSchedule(for operation: RegionalOperation, on date: Date) -> [PickupRoute] {
    let availableStores = operation.groceryStores.filter { $0.isActive }
    let availableFoodBanks = operation.foodBanks.filter { $0.isActive }

    guard !availableStores.isEmpty && !availableFoodBanks.isEmpty else {
      return []
    }

    // Group donations by urgency (expiration date)
    let pendingDonations = availableStores.flatMap { $0.donations.filter { $0.status == .pending } }
    let urgentDonations = pendingDonations.filter { donation in
      guard let expirationDate = donation.expirationDate else { return false }
      return expirationDate.timeIntervalSince(date) < 2 * 24 * 3600  // Within 2 days
    }

    let regularDonations = pendingDonations.filter { donation in
      guard let expirationDate = donation.expirationDate else { return true }
      return expirationDate.timeIntervalSince(date) >= 2 * 24 * 3600
    }

    var routes: [PickupRoute] = []

    // Create urgent pickup route
    if !urgentDonations.isEmpty {
      let urgentRoute = createRoute(
        for: urgentDonations,
        operation: operation,
        date: date,
        startTime: getNextAvailableTime(for: date, operation: operation),
        isUrgent: true
      )
      routes.append(urgentRoute)
    }

    // Partition regular donations based on number of trucks
    let truckCount = operation.numberOfTrucks
    let donationsPerTruck = Int(ceil(Double(regularDonations.count) / Double(truckCount)))
    
    for i in 0..<truckCount {
        let start = i * donationsPerTruck
        if start >= regularDonations.count { break }
        let end = min(start + donationsPerTruck, regularDonations.count)
        let truckDonations = Array(regularDonations[start..<end])
        
        let regularRoute = createRoute(
          for: truckDonations,
          operation: operation,
          date: date,
          startTime: getNextAvailableTime(
            for: date, operation: operation, after: routes.last?.endTime),
          isUrgent: false
        )
        routes.append(regularRoute)
    }

    return routes
  }

  private func createRoute(
    for donations: [Donation], operation: RegionalOperation, date: Date, startTime: Date,
    isUrgent: Bool
  ) -> PickupRoute {
    // Group donations by store
    let donationsByStore = Dictionary(grouping: donations) { $0.groceryStore }

    // Create pickups for each store
    var pickups: [Pickup] = []
    for (store, storeDonations) in donationsByStore {
      guard let store = store else { continue }

      let pickupTime = calculateOptimalPickupTime(for: store, on: date, startTime: startTime)
      let pickup = Pickup(scheduledTime: pickupTime)
      pickup.groceryStore = store
      pickup.donations = storeDonations

      // Update donation status
      for donation in storeDonations {
        donation.pickup = pickup
        donation.status = .scheduled
      }

      pickups.append(pickup)
    }

    // Create deliveries for food banks
    var deliveries: [Delivery] = []

    // Sort food banks by matching priority needs
    let sortedFoodBanks = operation.foodBanks.sorted { bank1, bank2 in
        let matchingNeeds1 = bank1.priorityNeeds.filter { need in donations.contains(where: { $0.foodType == need }) }.count
        let matchingNeeds2 = bank2.priorityNeeds.filter { need in donations.contains(where: { $0.foodType == need }) }.count
        return matchingNeeds1 > matchingNeeds2
    }

    var remainingDonations = donations
    for foodBank in sortedFoodBanks {
      guard foodBank.isActive && foodBank.availableCapacity > 0 && !remainingDonations.isEmpty else {
        continue
      }

      // Find donations that match this food bank's needs first
      let matchingDonations = remainingDonations.filter { foodBank.priorityNeeds.contains($0.foodType) }
      let otherDonations = remainingDonations.filter { !foodBank.priorityNeeds.contains($0.foodType) }
      
      var bankDonations: [Donation] = []
      var currentBankWeight = 0.0
      let capacity = Double(foodBank.availableCapacity)
      
      // Add matching ones first
      for donation in matchingDonations {
          if currentBankWeight + donation.quantity <= capacity {
              bankDonations.append(donation)
              currentBankWeight += donation.quantity
          }
      }
      
      // Add others if there is still capacity
      for donation in otherDonations {
          if currentBankWeight + donation.quantity <= capacity {
              bankDonations.append(donation)
              currentBankWeight += donation.quantity
          }
      }
      
      if bankDonations.isEmpty { continue }

      let deliveryTime = calculateOptimalDeliveryTime(for: foodBank, on: date, after: startTime)
      let delivery = Delivery(scheduledTime: deliveryTime)
      delivery.foodBank = foodBank
      delivery.donations = bankDonations

      for donation in bankDonations {
        donation.delivery = delivery
        remainingDonations.removeAll { $0.id == donation.id }
      }

      deliveries.append(delivery)
    }

    // Create the route
    let endTime = startTime.addingTimeInterval(4 * 3600)  // 4-hour window
    let route = PickupRoute(date: date, startTime: startTime, endTime: endTime)
    route.regionalOperation = operation
    route.pickups = pickups
    route.deliveries = deliveries

    // Optimize the route
    let optimizedRoute = routeOptimizer.optimizeRoute(
      pickups: pickups,
      deliveries: deliveries,
      startLocation: operation.regionCenter
    )

    route.totalDistance = optimizedRoute.totalDistance
    route.estimatedDuration = optimizedRoute.estimatedDuration

    return route
  }

  private func calculateOptimalPickupTime(for store: GroceryStore, on date: Date, startTime: Date)
    -> Date
  {
    // Consider store's preferred pickup times and operating hours
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)

    // Default to 9 AM if no preference
    components.hour = 9
    components.minute = 0

    let baseTime = calendar.date(from: components) ?? startTime

    // Adjust based on store preferences
    if !store.preferredPickupTimes.isEmpty {
      // Parse preferred times (simplified - in real app, parse more complex time strings)
      if store.preferredPickupTimes.contains("morning") {
        components.hour = 8
      } else if store.preferredPickupTimes.contains("afternoon") {
        components.hour = 14
      }
    }

    return calendar.date(from: components) ?? baseTime
  }

  private func calculateOptimalDeliveryTime(
    for foodBank: FoodBank, on date: Date, after startTime: Date
  ) -> Date {
    // Consider food bank's operating hours
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)

    // Default to 2 hours after start time
    let baseTime = startTime.addingTimeInterval(2 * 3600)
    components.hour = calendar.component(.hour, from: baseTime)
    components.minute = calendar.component(.minute, from: baseTime)

    return calendar.date(from: components) ?? baseTime
  }

  private func getNextAvailableTime(
    for date: Date, operation: RegionalOperation, after previousEndTime: Date? = nil
  ) -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: date)

    if let previousEnd = previousEndTime {
      // Start 30 minutes after previous route ends
      let nextTime = previousEnd.addingTimeInterval(30 * 60)
      components.hour = calendar.component(.hour, from: nextTime)
      components.minute = calendar.component(.minute, from: nextTime)
    } else {
      // Default to 8 AM
      components.hour = 8
      components.minute = 0
    }

    return calendar.date(from: components) ?? date
  }
}
