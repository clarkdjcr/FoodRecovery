//
//  FoodRecoveryApp.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftData
import SwiftUI

@main
struct FoodRecoveryApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      RegionalOperation.self,
      FoodBank.self,
      GroceryStore.self,
      Restaurant.self,
      RestaurantDonation.self,
      Donation.self,
      Pickup.self,
      Delivery.self,
      PickupRoute.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      print("ModelContainer creation failed with error: \(error)")
      print("Error details: \(String(describing: error))")
      if let localizedError = error as? LocalizedError {
        print("Localized description: \(localizedError.localizedDescription)")
        print("Failure reason: \(localizedError.failureReason ?? "None")")
        print("Recovery suggestion: \(localizedError.recoverySuggestion ?? "None")")
      }
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .task {
          await NotificationService.shared.requestPermission()
        }
    }
    .modelContainer(sharedModelContainer)
  }
}
