// FirestoreModels.swift
// Codable document structs that mirror the SwiftData models for Firestore persistence.
// Each document uses the SwiftData model's UUID string as its Firestore document ID.

import Foundation

// MARK: - Operation

struct OperationDocument: Codable, Identifiable {
    var id: String
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

    init(from model: RegionalOperation) {
        self.id = model.id.uuidString
        self.name = model.name
        self.regionCenterLatitude = model.regionCenterLatitude
        self.regionCenterLongitude = model.regionCenterLongitude
        self.radiusMiles = model.radiusMiles
        self.maxFoodBanks = model.maxFoodBanks
        self.operationHours = model.operationHours
        self.contactEmail = model.contactEmail
        self.contactPhone = model.contactPhone
        self.numberOfTrucks = model.numberOfTrucks
        self.createdAt = model.createdAt
        self.isActive = model.isActive
    }
}

// MARK: - Food Bank

struct FoodBankDocument: Codable, Identifiable {
    var id: String
    var operationId: String
    var name: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var capacity: Int
    var dailyUsage: Int
    var contactName: String
    var contactEmail: String
    var contactPhone: String
    var operatingHours: String
    var specialRequirements: String
    var priorityNeeds: [String]
    var isActive: Bool
    var createdAt: Date
    var lastDelivery: Date?

    init(from model: FoodBank, operationId: String) {
        self.id = model.id.uuidString
        self.operationId = operationId
        self.name = model.name
        self.address = model.address
        self.latitude = model.latitude
        self.longitude = model.longitude
        self.capacity = model.capacity
        self.dailyUsage = model.dailyUsage
        self.contactName = model.contactName
        self.contactEmail = model.contactEmail
        self.contactPhone = model.contactPhone
        self.operatingHours = model.operatingHours
        self.specialRequirements = model.specialRequirements
        self.priorityNeeds = model.priorityNeeds.map(\.rawValue)
        self.isActive = model.isActive
        self.createdAt = model.createdAt
        self.lastDelivery = model.lastDelivery
    }
}

// MARK: - Food Provider

struct FoodProviderDocument: Codable, Identifiable {
    var id: String
    var operationId: String
    var name: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var contactName: String
    var contactEmail: String
    var contactPhone: String
    var donationEmail: String
    var operatingHours: String
    var preferredPickupTimes: String
    var isActive: Bool
    var createdAt: Date
    var lastPickup: Date?

    init(from model: FoodProvider, operationId: String) {
        self.id = model.id.uuidString
        self.operationId = operationId
        self.name = model.name
        self.address = model.address
        self.latitude = model.latitude
        self.longitude = model.longitude
        self.contactName = model.contactName
        self.contactEmail = model.contactEmail
        self.contactPhone = model.contactPhone
        self.donationEmail = model.donationEmail
        self.operatingHours = model.operatingHours
        self.preferredPickupTimes = model.preferredPickupTimes
        self.isActive = model.isActive
        self.createdAt = model.createdAt
        self.lastPickup = model.lastPickup
    }
}

// MARK: - Restaurant

struct RestaurantDocument: Codable, Identifiable {
    var id: String
    var operationId: String
    var name: String
    var businessName: String
    var ein: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var restaurantType: String
    var cuisineTypesRaw: String
    var avgDailyCovers: Int
    var avgTicketValue: Double
    var serviceHours: String
    var kitchenHours: String
    var preferredPickupWindow: String
    var daysOfOperationRaw: String
    var storageCapabilitiesRaw: String
    var foodSafetyCertificationsRaw: String
    var lastHealthInspection: Date?
    var healthGrade: String
    var taxID: String
    var estimatedDailyWaste: Double
    var estimatedDailyWastePounds: Double
    var participatesInFoodRecovery: Bool
    var ownerName: String
    var managerName: String
    var contactEmail: String
    var contactPhone: String
    var accountingEmail: String
    var donationTypesRaw: String
    var specialInstructions: String
    var requiresPhotography: Bool
    var isActive: Bool
    var createdAt: Date
    var totalDonationsValue: Double
    var totalDonationsPounds: Double
    var totalTaxBenefit: Double

    init(from model: Restaurant, operationId: String) {
        self.id = model.id.uuidString
        self.operationId = operationId
        self.name = model.name
        self.businessName = model.businessName
        self.ein = model.ein
        self.address = model.address
        self.latitude = model.latitude
        self.longitude = model.longitude
        self.restaurantType = model.restaurantType.rawValue
        self.cuisineTypesRaw = model.cuisineTypesRaw
        self.avgDailyCovers = model.avgDailyCovers
        self.avgTicketValue = model.avgTicketValue
        self.serviceHours = model.serviceHours
        self.kitchenHours = model.kitchenHours
        self.preferredPickupWindow = model.preferredPickupWindow
        self.daysOfOperationRaw = model.daysOfOperationRaw
        self.storageCapabilitiesRaw = model.storageCapabilitiesRaw
        self.foodSafetyCertificationsRaw = model.foodSafetyCertificationsRaw
        self.lastHealthInspection = model.lastHealthInspection
        self.healthGrade = model.healthGrade
        self.taxID = model.taxID
        self.estimatedDailyWaste = model.estimatedDailyWaste
        self.estimatedDailyWastePounds = model.estimatedDailyWastePounds
        self.participatesInFoodRecovery = model.participatesInFoodRecovery
        self.ownerName = model.ownerName
        self.managerName = model.managerName
        self.contactEmail = model.contactEmail
        self.contactPhone = model.contactPhone
        self.accountingEmail = model.accountingEmail
        self.donationTypesRaw = model.donationTypesRaw
        self.specialInstructions = model.specialInstructions
        self.requiresPhotography = model.requiresPhotography
        self.isActive = model.isActive
        self.createdAt = model.createdAt
        self.totalDonationsValue = model.totalDonationsValue
        self.totalDonationsPounds = model.totalDonationsPounds
        self.totalTaxBenefit = model.totalTaxBenefit
    }
}

// MARK: - Donation

struct DonationDocument: Codable, Identifiable {
    var id: String
    var operationId: String
    var providerId: String?
    var foodType: String
    var quantity: Double
    var expirationDate: Date?
    var foodDescription: String
    var status: String
    var createdAt: Date
    var emailSource: String
    var emailSubject: String
    var emailBody: String
    var aiExtractedData: String
    var aiConfidence: Double
    var isVerified: Bool
    var carbonOffset: Double

    init(from model: Donation, operationId: String, providerId: String? = nil) {
        self.id = model.id.uuidString
        self.operationId = operationId
        self.providerId = providerId
        self.foodType = model.foodType.rawValue
        self.quantity = model.quantity
        self.expirationDate = model.expirationDate
        self.foodDescription = model.foodDescription
        self.status = model.status.rawValue
        self.createdAt = model.createdAt
        self.emailSource = model.emailSource
        self.emailSubject = model.emailSubject
        self.emailBody = model.emailBody
        self.aiExtractedData = model.aiExtractedData
        self.aiConfidence = model.aiConfidence
        self.isVerified = model.isVerified
        self.carbonOffset = model.carbonOffset
    }
}

// MARK: - Pickup Route

struct PickupRouteDocument: Codable, Identifiable {
    var id: String
    var operationId: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var status: String
    var totalDistance: Double
    var estimatedDuration: Double
    var actualDuration: Double?
    var notes: String
    var createdAt: Date
    var completedAt: Date?
    var currentStopIndex: Int
    var vehicleId: String?

    init(from model: PickupRoute, operationId: String) {
        self.id = model.id.uuidString
        self.operationId = operationId
        self.date = model.date
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.status = model.status.rawValue
        self.totalDistance = model.totalDistance
        self.estimatedDuration = model.estimatedDuration
        self.actualDuration = model.actualDuration
        self.notes = model.notes
        self.createdAt = model.createdAt
        self.completedAt = model.completedAt
        self.currentStopIndex = model.currentStopIndex
        self.vehicleId = model.vehicleId
    }
}

// MARK: - Pickup

struct PickupDocument: Codable, Identifiable {
    var id: String
    var routeId: String
    var operationId: String
    var providerId: String?
    var restaurantId: String?
    var scheduledTime: Date
    var actualTime: Date?
    var status: String
    var notes: String
    var createdAt: Date
    var confirmedAt: Date?
    var completedAt: Date?
    var proofPhotoURL: String?

    init(from model: Pickup, routeId: String, operationId: String) {
        self.id = model.id.uuidString
        self.routeId = routeId
        self.operationId = operationId
        self.providerId = model.foodProvider?.id.uuidString
        self.restaurantId = model.restaurant?.id.uuidString
        self.scheduledTime = model.scheduledTime
        self.actualTime = model.actualTime
        self.status = model.status.rawValue
        self.notes = model.notes
        self.createdAt = model.createdAt
        self.confirmedAt = model.confirmedAt
        self.completedAt = model.completedAt
        self.proofPhotoURL = nil
    }
}

// MARK: - Delivery

struct DeliveryDocument: Codable, Identifiable {
    var id: String
    var routeId: String
    var operationId: String
    var foodBankId: String?
    var scheduledTime: Date
    var actualTime: Date?
    var status: String
    var notes: String
    var createdAt: Date
    var confirmedAt: Date?
    var completedAt: Date?
    var proofPhotoURL: String?

    init(from model: Delivery, routeId: String, operationId: String) {
        self.id = model.id.uuidString
        self.routeId = routeId
        self.operationId = operationId
        self.foodBankId = model.foodBank?.id.uuidString
        self.scheduledTime = model.scheduledTime
        self.actualTime = model.actualTime
        self.status = model.status.rawValue
        self.notes = model.notes
        self.createdAt = model.createdAt
        self.confirmedAt = model.confirmedAt
        self.completedAt = model.completedAt
        self.proofPhotoURL = nil
    }
}

// MARK: - Restaurant Donation

struct RestaurantDonationDocument: Codable, Identifiable {
    var id: String
    var restaurantId: String?
    var operationId: String
    var donationDate: Date
    var itemDescription: String
    var category: String
    var quantity: Double
    var unit: String
    var fairMarketValue: Double
    var costBasis: Double
    var enhancedDeduction: Double
    var notes: String
    var expirationDate: Date?
    var form8283Required: Bool
    var donationReceiptGenerated: Bool
    var donationReceiptURL: String
    var photoURLsRaw: String

    init(from model: RestaurantDonation, operationId: String) {
        self.id = model.id.uuidString
        self.restaurantId = model.restaurant?.id.uuidString
        self.operationId = operationId
        self.donationDate = model.donationDate
        self.itemDescription = model.itemDescription
        self.category = model.category
        self.quantity = model.quantity
        self.unit = model.unit
        self.fairMarketValue = model.fairMarketValue
        self.costBasis = model.costBasis
        self.enhancedDeduction = model.enhancedDeduction
        self.notes = model.notes
        self.expirationDate = model.expirationDate
        self.form8283Required = model.form8283Required
        self.donationReceiptGenerated = model.donationReceiptGenerated
        self.donationReceiptURL = model.donationReceiptURL
        self.photoURLsRaw = model.photoURLsRaw
    }
}

// MARK: - User Profile (stored in Firestore alongside Firebase Auth)

struct UserProfileDocument: Codable, Identifiable {
    var id: String            // Firebase Auth UID
    var email: String
    var displayName: String
    var operationId: String?  // The regional operation this user manages
    var role: String          // "admin", "operator", "driver"
    var createdAt: Date

    static func makeNew(uid: String, email: String, displayName: String) -> UserProfileDocument {
        UserProfileDocument(
            id: uid,
            email: email,
            displayName: displayName,
            operationId: nil,
            role: "operator",
            createdAt: Date()
        )
    }
}
