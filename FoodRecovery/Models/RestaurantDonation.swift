//
//  RestaurantDonation.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import Foundation
import SwiftData

@Model
final class RestaurantDonation {
    var id: UUID
    var donationDate: Date
    var itemDescription: String
    var category: String // "prepared_meals", "baked_goods", "ingredients"
    var quantity: Double
    var unit: String // "servings", "pounds", "items"
    var fairMarketValue: Double // For tax purposes
    var costBasis: Double // Restaurant's cost
    var enhancedDeduction: Double // 115% of cost basis
    var temperatureAtPickup: Double?
    var photosRequired: Bool = false
    var photoURLsRaw: String = "" // JSON string of photo URLs
    var nutritionalInfo: String = ""
    var expirationDate: Date?
    var pickupTime: Date?
    var deliveredTime: Date?
    var notes: String = ""
    
    // Tax Documentation
    var form8283Required: Bool = false // Required for donations over $500
    var donationReceiptGenerated: Bool = false
    var donationReceiptURL: String = ""
    
    // Computed Properties for Type-Safe Array Access
    var photoURLs: [String] {
        get { photoURLsRaw.isEmpty ? [] : photoURLsRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        set { photoURLsRaw = newValue.joined(separator: ", ") }
    }
    
    // Relationships
    @Relationship var restaurant: Restaurant?
    @Relationship var pickup: Pickup?
    
    init(
        itemDescription: String,
        category: String,
        quantity: Double,
        unit: String,
        fairMarketValue: Double,
        costBasis: Double
    ) {
        self.id = UUID()
        self.donationDate = Date()
        self.itemDescription = itemDescription
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.fairMarketValue = fairMarketValue
        self.costBasis = costBasis
        self.enhancedDeduction = costBasis * 1.15
        self.form8283Required = fairMarketValue > 500
    }
    
    var taxBenefit: Double {
        enhancedDeduction
    }
}
