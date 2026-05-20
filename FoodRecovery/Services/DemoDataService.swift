//
//  DemoDataService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation
import SwiftData

class DemoDataService {

  static func createDemoData(modelContext: ModelContext) {
    // Create a demo regional operation
    let operation = RegionalOperation(
      name: "San Francisco Bay Area Food Recovery",
      regionCenter: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      radiusMiles: 35.0,
      maxFoodBanks: 5,
      operationHours: "8:00 AM - 6:00 PM",
      contactEmail: "operations@sfbayfoodrecovery.org",
      contactPhone: "(555) 123-4567"
    )

    modelContext.insert(operation)

    // Create demo food banks
    let foodBank1 = FoodBank(
      name: "San Francisco Food Bank",
      address: "900 Pennsylvania Ave, San Francisco, CA 94107",
      latitude: 37.7749,
      longitude: -122.4194,
      capacity: 2000,
      dailyUsage: 1200,
      contactName: "Sarah Johnson",
      contactEmail: "sarah@sfoodbank.org",
      contactPhone: "(555) 234-5678",
      operatingHours: "9:00 AM - 5:00 PM",
      specialRequirements: "Refrigerated storage available"
    )

    let foodBank2 = FoodBank(
      name: "Oakland Community Food Bank",
      address: "7900 Edgewater Dr, Oakland, CA 94621",
      latitude: 37.8044,
      longitude: -122.2712,
      capacity: 1500,
      dailyUsage: 800,
      contactName: "Michael Chen",
      contactEmail: "michael@oaklandfoodbank.org",
      contactPhone: "(555) 345-6789",
      operatingHours: "8:00 AM - 6:00 PM",
      specialRequirements: "Loading dock available"
    )

    let foodBank3 = FoodBank(
      name: "San Jose Food Bank",
      address: "750 Curtner Ave, San Jose, CA 95125",
      latitude: 37.3382,
      longitude: -121.8863,
      capacity: 1800,
      dailyUsage: 1000,
      contactName: "Lisa Rodriguez",
      contactEmail: "lisa@sjfoodbank.org",
      contactPhone: "(555) 456-7890",
      operatingHours: "9:00 AM - 4:00 PM",
      specialRequirements: "Forklift available for heavy items"
    )

    foodBank1.regionalOperation = operation
    foodBank2.regionalOperation = operation
    foodBank3.regionalOperation = operation

    operation.foodBanks.append(contentsOf: [foodBank1, foodBank2, foodBank3])

    modelContext.insert(foodBank1)
    modelContext.insert(foodBank2)
    modelContext.insert(foodBank3)

    // Create demo grocery stores
    let store1 = GroceryStore(
      name: "Whole Foods Market - Market Street",
      address: "399 4th St, San Francisco, CA 94107",
      latitude: 37.7849,
      longitude: -122.4094,
      contactName: "David Kim",
      contactEmail: "david.kim@wholefoods.com",
      contactPhone: "(555) 567-8901",
      donationEmail: "donations-sf@wholefoods.com",
      operatingHours: "7:00 AM - 10:00 PM",
      preferredPickupTimes: "morning"
    )

    let store2 = GroceryStore(
      name: "Safeway - Mission District",
      address: "2020 Market St, San Francisco, CA 94114",
      latitude: 37.7649,
      longitude: -122.4294,
      contactName: "Jennifer Martinez",
      contactEmail: "jennifer.martinez@safeway.com",
      contactPhone: "(555) 678-9012",
      donationEmail: "donations-mission@safeway.com",
      operatingHours: "6:00 AM - 11:00 PM",
      preferredPickupTimes: "afternoon"
    )

    let store3 = GroceryStore(
      name: "Trader Joe's - Berkeley",
      address: "1885 Solano Ave, Berkeley, CA 94707",
      latitude: 37.8715,
      longitude: -122.2730,
      contactName: "Robert Wilson",
      contactEmail: "robert.wilson@traderjoes.com",
      contactPhone: "(555) 789-0123",
      donationEmail: "donations-berkeley@traderjoes.com",
      operatingHours: "8:00 AM - 9:00 PM",
      preferredPickupTimes: "flexible"
    )

    store1.regionalOperation = operation
    store2.regionalOperation = operation
    store3.regionalOperation = operation

    operation.groceryStores.append(contentsOf: [store1, store2, store3])

    modelContext.insert(store1)
    modelContext.insert(store2)
    modelContext.insert(store3)

    // Create demo donations
    let donation1 = Donation(
      foodType: .produce,
      quantity: 45.5,
      expirationDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
      description: "Mixed vegetables including carrots, broccoli, lettuce, and bell peppers",
      emailSource: "donations-sf@wholefoods.com",
      emailSubject: "Daily Donation - Fresh Produce",
      emailBody:
        "We have 45.5 lbs of fresh produce available for donation. Items include carrots, broccoli, lettuce, and bell peppers. Expires in 2 days.",
      aiExtractedData:
        "{\"confidence\": 0.95, \"foodType\": \"produce\", \"quantity\": 45.5, \"expirationDate\": \"2024-01-15\"}"
    )

    let donation2 = Donation(
      foodType: .bakery,
      quantity: 28.0,
      expirationDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
      description: "Assorted bread, pastries, and baked goods",
      emailSource: "donations-mission@safeway.com",
      emailSubject: "Bakery Donation Available",
      emailBody:
        "We have 28 lbs of bakery items including bread, pastries, and other baked goods. Best used within 1 day.",
      aiExtractedData:
        "{\"confidence\": 0.88, \"foodType\": \"bakery\", \"quantity\": 28.0, \"expirationDate\": \"2024-01-14\"}"
    )

    let donation3 = Donation(
      foodType: .dairy,
      quantity: 32.0,
      expirationDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
      description: "Milk, yogurt, and cheese products",
      emailSource: "donations-berkeley@traderjoes.com",
      emailSubject: "Dairy Products Donation",
      emailBody:
        "We have 32 lbs of dairy products including milk, yogurt, and cheese. Expires in 3 days.",
      aiExtractedData:
        "{\"confidence\": 0.92, \"foodType\": \"dairy\", \"quantity\": 32.0, \"expirationDate\": \"2024-01-16\"}"
    )

    donation1.groceryStore = store1
    donation2.groceryStore = store2
    donation3.groceryStore = store3

    store1.donations.append(donation1)
    store2.donations.append(donation2)
    store3.donations.append(donation3)

    modelContext.insert(donation1)
    modelContext.insert(donation2)
    modelContext.insert(donation3)

    // Save all demo data
    do {
      try modelContext.save()
    } catch {
      print("Failed to save demo data: \(error)")
    }
  }
}
