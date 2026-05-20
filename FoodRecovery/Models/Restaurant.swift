//
//  Restaurant.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import Foundation
import SwiftData

enum RestaurantType: String, CaseIterable, Codable {
    case fastFood = "fast_food"
    case casualDining = "casual_dining"
    case fineDining = "fine_dining"
    case cafe = "cafe"
    case bakery = "bakery"
    case pizzeria = "pizzeria"
    case ethnic = "ethnic"
    case buffet = "buffet"
    case catering = "catering"
    case foodTruck = "food_truck"
    
    var displayName: String {
        switch self {
        case .fastFood: return "Fast Food"
        case .casualDining: return "Casual Dining"
        case .fineDining: return "Fine Dining"
        case .cafe: return "Café"
        case .bakery: return "Bakery"
        case .pizzeria: return "Pizzeria"
        case .ethnic: return "Ethnic Cuisine"
        case .buffet: return "Buffet"
        case .catering: return "Catering"
        case .foodTruck: return "Food Truck"
        }
    }
}

enum StorageCapability: String, CaseIterable, Codable {
    case hotHolding = "hot_holding"
    case refrigerated = "refrigerated"
    case frozen = "frozen"
    case pantry = "pantry"
    case bakery = "bakery_items"
    
    var displayName: String {
        switch self {
        case .hotHolding: return "Hot Holding (140°F+)"
        case .refrigerated: return "Refrigerated (32-40°F)"
        case .frozen: return "Frozen (0°F or below)"
        case .pantry: return "Pantry Items"
        case .bakery: return "Baked Goods"
        }
    }
    
    var icon: String {
        switch self {
        case .hotHolding: return "flame.fill"
        case .refrigerated: return "snowflake"
        case .frozen: return "snow"
        case .pantry: return "archivebox.fill"
        case .bakery: return "birthday.cake.fill"
        }
    }
}

enum FoodSafetyCertification: String, CaseIterable, Codable {
    case servsafe = "servsafe"
    case haccp = "haccp"
    case stateLocal = "state_local"
    case organic = "organic"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .servsafe: return "ServSafe Certified"
        case .haccp: return "HACCP Certified"
        case .stateLocal: return "State/Local Certification"
        case .organic: return "Organic Certified"
        case .none: return "Basic Food Handler"
        }
    }
}

@Model
final class Restaurant {
    var id: UUID
    var name: String
    var businessName: String // Legal business name for tax purposes
    var ein: String // Employer Identification Number for tax reporting
    var address: String
    var latitude: Double?
    var longitude: Double?
    
    // Business Details
    var restaurantType: RestaurantType
    var cuisineTypesRaw: String = "" // JSON string of cuisine types
    var avgDailyCovers: Int // Average customers served daily
    var avgTicketValue: Double // Average order value for tax calculations
    
    // Operational Information
    var serviceHours: String
    var kitchenHours: String // When food prep stops
    var preferredPickupWindow: String // e.g., "8:00 PM - 9:30 PM"
    var daysOfOperationRaw: String = "" // JSON string of days
    
    // Food Safety & Storage
    var storageCapabilitiesRaw: String = "" // JSON string of storage capabilities
    var foodSafetyCertificationsRaw: String = "" // JSON string of certifications
    var lastHealthInspection: Date?
    var healthGrade: String = "" // A, B, C, etc.
    
    // Tax & Donation Information
    var taxID: String // For donation documentation
    var estimatedDailyWaste: Double // In dollars
    var estimatedDailyWastePounds: Double // In pounds
    var participatesInFoodRecovery: Bool = false
    var annualRevenueRange: String = "" // For tax benefit calculations
    
    // Contact Information
    var ownerName: String
    var managerName: String
    var contactEmail: String
    var contactPhone: String
    var accountingEmail: String // For tax documentation
    
    // Preferences
    var donationTypesRaw: String = "" // JSON string of donation types
    var specialInstructions: String = ""
    var requiresPhotography: Bool = false // For tax documentation
    var maxPickupDelay: Int = 2 // Hours after kitchen close
    
    // Tracking
    var isActive: Bool
    var createdAt: Date
    var lastDonation: Date?
    var totalDonationsValue: Double = 0.0
    var totalDonationsPounds: Double = 0.0
    var totalTaxBenefit: Double = 0.0
    
    // Relationships
    @Relationship var regionalOperation: RegionalOperation?
    @Relationship(deleteRule: .cascade) var donations: [RestaurantDonation] = []
    @Relationship(deleteRule: .cascade) var pickups: [Pickup] = []
    
    // Computed Properties for Type-Safe Array Access
    var cuisineTypes: [String] {
        get { cuisineTypesRaw.isEmpty ? [] : (cuisineTypesRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }) }
        set { cuisineTypesRaw = newValue.joined(separator: ", ") }
    }
    
    var daysOfOperation: [String] {
        get { daysOfOperationRaw.isEmpty ? [] : daysOfOperationRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        set { daysOfOperationRaw = newValue.joined(separator: ", ") }
    }
    
    var storageCapabilities: [StorageCapability] {
        get {
            storageCapabilitiesRaw.isEmpty ? [] : storageCapabilitiesRaw.components(separatedBy: ",").compactMap { 
                StorageCapability(rawValue: $0.trimmingCharacters(in: .whitespaces)) 
            }
        }
        set { storageCapabilitiesRaw = newValue.map(\.rawValue).joined(separator: ", ") }
    }
    
    var foodSafetyCertifications: [FoodSafetyCertification] {
        get {
            foodSafetyCertificationsRaw.isEmpty ? [] : foodSafetyCertificationsRaw.components(separatedBy: ",").compactMap { 
                FoodSafetyCertification(rawValue: $0.trimmingCharacters(in: .whitespaces)) 
            }
        }
        set { foodSafetyCertificationsRaw = newValue.map(\.rawValue).joined(separator: ", ") }
    }
    
    var donationTypes: [String] {
        get { donationTypesRaw.isEmpty ? [] : donationTypesRaw.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
        set { donationTypesRaw = newValue.joined(separator: ", ") }
    }
    
    init(
        name: String,
        businessName: String,
        ein: String,
        address: String,
        latitude: Double?,
        longitude: Double?,
        restaurantType: RestaurantType,
        avgDailyCovers: Int,
        avgTicketValue: Double,
        serviceHours: String,
        kitchenHours: String,
        preferredPickupWindow: String,
        ownerName: String,
        managerName: String,
        contactEmail: String,
        contactPhone: String,
        accountingEmail: String,
        estimatedDailyWaste: Double,
        estimatedDailyWastePounds: Double
    ) {
        self.id = UUID()
        self.name = name
        self.businessName = businessName
        self.ein = ein
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.restaurantType = restaurantType
        self.avgDailyCovers = avgDailyCovers
        self.avgTicketValue = avgTicketValue
        self.serviceHours = serviceHours
        self.kitchenHours = kitchenHours
        self.preferredPickupWindow = preferredPickupWindow
        self.ownerName = ownerName
        self.managerName = managerName
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.accountingEmail = accountingEmail
        self.estimatedDailyWaste = estimatedDailyWaste
        self.estimatedDailyWastePounds = estimatedDailyWastePounds
        self.taxID = ein // Use EIN as tax ID for now
        self.isActive = true
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var estimatedAnnualWasteValue: Double {
        estimatedDailyWaste * Double(daysOfOperation.count) * 52 // 52 weeks
    }
    
    var estimatedAnnualTaxBenefit: Double {
        // Enhanced deduction: 15% above cost basis
        estimatedAnnualWasteValue * 1.15
    }
    
    var currentMonthDonations: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = donations.filter { donation in
            calendar.isDate(donation.donationDate, equalTo: now, toGranularity: .month)
        }
        return currentMonth.reduce(0) { $0 + $1.fairMarketValue }
    }
    
    var wasteReductionPercentage: Double {
        guard estimatedDailyWaste > 0 else { return 0 }
        let avgDailyDonation = totalDonationsValue / max(1, daysSinceJoined)
        return (avgDailyDonation / estimatedDailyWaste) * 100
    }
    
    private var daysSinceJoined: Double {
        Date().timeIntervalSince(createdAt) / (24 * 60 * 60)
    }
}
