//
//  RegionalOperationViewModel.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

@MainActor
class RegionalOperationViewModel: ObservableObject {
  @Published var operations: [RegionalOperation] = []
  @Published var selectedOperation: RegionalOperation?
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let schedulingService = SchedulingService()
  private let emailService: EmailService

  init() {
    self.emailService = EmailService()
  }

  func loadOperations(modelContext: ModelContext) {
    do {
      let descriptor = FetchDescriptor<RegionalOperation>(
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
      )
      operations = try modelContext.fetch(descriptor)
    } catch {
      errorMessage = "Failed to load operations: \(error.localizedDescription)"
    }
  }

  func createOperation(
    modelContext: ModelContext,
    name: String, regionCenter: CLLocationCoordinate2D, radiusMiles: Double, maxFoodBanks: Int,
    operationHours: String, contactEmail: String, contactPhone: String
  ) {
    let operation = RegionalOperation(
      name: name,
      regionCenter: regionCenter,
      radiusMiles: radiusMiles,
      maxFoodBanks: maxFoodBanks,
      operationHours: operationHours,
      contactEmail: contactEmail,
      contactPhone: contactPhone
    )

    modelContext.insert(operation)

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to create operation: \(error.localizedDescription)"
    // }
  }

  func addFoodBank(
    modelContext: ModelContext,
    to operation: RegionalOperation, name: String, address: String,
    location: CLLocationCoordinate2D, capacity: Int, dailyUsage: Int, contactName: String,
    contactEmail: String, contactPhone: String, operatingHours: String, specialRequirements: String
  ) {
    let foodBank = FoodBank(
      name: name,
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
      capacity: capacity,
      dailyUsage: dailyUsage,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      operatingHours: operatingHours,
      specialRequirements: specialRequirements
    )

    foodBank.regionalOperation = operation
    operation.foodBanks.append(foodBank)

    modelContext.insert(foodBank)

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to add food bank: \(error.localizedDescription)"
    // }
    loadOperations(modelContext: modelContext)
  }

  func addGroceryStore(
    modelContext: ModelContext,
    to operation: RegionalOperation, name: String, address: String,
    location: CLLocationCoordinate2D, contactName: String, contactEmail: String,
    contactPhone: String, donationEmail: String, operatingHours: String,
    preferredPickupTimes: String
  ) {
    let store = GroceryStore(
      name: name,
      address: address,
      latitude: location.latitude,
      longitude: location.longitude,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      donationEmail: donationEmail,
      operatingHours: operatingHours,
      preferredPickupTimes: preferredPickupTimes
    )

    store.regionalOperation = operation
    operation.groceryStores.append(store)
    modelContext.insert(store)
    loadOperations(modelContext: modelContext)
  }

  func generateDailySchedule(for operation: RegionalOperation, on date: Date) async {
    isLoading = true
    errorMessage = nil

    do {
      let routes = schedulingService.generatePickupSchedule(for: operation, on: date)

      for route in routes {
        operation.pickupRoutes.append(route)
        // modelContext.insert(route)

        // Send email confirmations
        try await emailService.sendRouteConfirmation(to: operation, route: route)

        for pickup in route.pickups {
          if let store = pickup.groceryStore {
            try await emailService.sendPickupConfirmation(to: store, pickup: pickup)
          }
        }

        for delivery in route.deliveries {
          if let foodBank = delivery.foodBank {
            try await emailService.sendDeliveryConfirmation(to: foodBank, delivery: delivery)
          }
        }
      }

      // try modelContext.save()
      // loadOperations(modelContext: modelContext)
    } catch {
      errorMessage = "Failed to generate schedule: \(error.localizedDescription)"
    }

    isLoading = false
  }

  func confirmPickup(_ pickup: Pickup) {
    pickup.status = .confirmed
    pickup.confirmedAt = Date()

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to confirm pickup: \(error.localizedDescription)"
    // }
  }

  func confirmDelivery(_ delivery: Delivery) {
    delivery.status = .confirmed
    delivery.confirmedAt = Date()

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to confirm delivery: \(error.localizedDescription)"
    // }
  }

  func completePickup(_ pickup: Pickup) {
    pickup.status = .completed
    pickup.completedAt = Date()
    pickup.actualTime = Date()

    // Update donation statuses
    for donation in pickup.donations {
      donation.status = .pickedUp
    }

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to complete pickup: \(error.localizedDescription)"
    // }
  }

  func completeDelivery(_ delivery: Delivery) {
    delivery.status = .completed
    delivery.completedAt = Date()
    delivery.actualTime = Date()

    // Update donation statuses
    for donation in delivery.donations {
      donation.status = .delivered
    }

    // do {
    //   try modelContext.save()
    //   loadOperations(modelContext: modelContext)
    // } catch {
    //   errorMessage = "Failed to complete delivery: \(error.localizedDescription)"
    // }
  }
}
