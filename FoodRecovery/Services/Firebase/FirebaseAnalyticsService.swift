// FirebaseAnalyticsService.swift
// Centralises all Firebase Analytics event logging.
// Call FirebaseAnalyticsService.shared.log(...) at key app actions.

import FirebaseAnalytics
import Foundation

final class FirebaseAnalyticsService {
    static let shared = FirebaseAnalyticsService()

    private init() {}

    // MARK: - Event logging

    func log(_ event: AppAnalyticsEvent) {
        let (name, params) = event.nameAndParams
        Analytics.logEvent(name, parameters: params)
    }

    func setUser(id: String) {
        Analytics.setUserID(id)
    }

    func setUserProperty(_ value: String, name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    func logScreen(_ name: String, className: String = "") {
        Analytics.logEvent(
            AnalyticsEventScreenView,
            parameters: [
                AnalyticsParameterScreenName: name,
                AnalyticsParameterScreenClass: className.isEmpty ? name : className
            ]
        )
    }
}

// MARK: - Event definitions

enum AppAnalyticsEvent {
    // Auth
    case userSignedIn(method: String)
    case userSignedUp
    case userSignedOut

    // Operations
    case operationCreated(name: String)

    // Food banks
    case foodBankAdded(name: String, operationId: String)

    // Food providers
    case foodProviderAdded(name: String, operationId: String)

    // Restaurants
    case restaurantRegistered(name: String, type: String)

    // Donations
    case donationCreated(foodType: String, quantityLbs: Double)
    case donationVerified(id: String)
    case donationStatusChanged(id: String, status: String)

    // Routes
    case routeGenerated(pickupCount: Int, deliveryCount: Int)
    case routeStarted(routeId: String)
    case routeCompleted(routeId: String, totalPounds: Double, distanceMiles: Double)

    // Pickups / Deliveries
    case pickupConfirmed(id: String)
    case pickupCompleted(id: String, quantityLbs: Double)
    case deliveryConfirmed(id: String)
    case deliveryCompleted(id: String, quantityLbs: Double)

    // AI Email processing
    case emailProcessed(aiProvider: String, confidence: Double, success: Bool)

    // Storage
    case photoUploaded(type: String)

    var nameAndParams: (String, [String: Any]) {
        switch self {
        case .userSignedIn(let method):
            return ("user_signed_in", ["method": method])
        case .userSignedUp:
            return ("user_signed_up", [:])
        case .userSignedOut:
            return ("user_signed_out", [:])

        case .operationCreated(let name):
            return ("operation_created", ["name": name])

        case .foodBankAdded(let name, let opId):
            return ("food_bank_added", ["name": name, "operation_id": opId])

        case .foodProviderAdded(let name, let opId):
            return ("food_provider_added", ["name": name, "operation_id": opId])

        case .restaurantRegistered(let name, let type):
            return ("restaurant_registered", ["name": name, "type": type])

        case .donationCreated(let foodType, let qty):
            return ("donation_created", ["food_type": foodType, "quantity_lbs": qty])
        case .donationVerified(let id):
            return ("donation_verified", ["donation_id": id])
        case .donationStatusChanged(let id, let status):
            return ("donation_status_changed", ["donation_id": id, "status": status])

        case .routeGenerated(let pickups, let deliveries):
            return ("route_generated", ["pickup_count": pickups, "delivery_count": deliveries])
        case .routeStarted(let id):
            return ("route_started", ["route_id": id])
        case .routeCompleted(let id, let lbs, let miles):
            return ("route_completed", ["route_id": id, "total_pounds": lbs, "distance_miles": miles])

        case .pickupConfirmed(let id):
            return ("pickup_confirmed", ["pickup_id": id])
        case .pickupCompleted(let id, let qty):
            return ("pickup_completed", ["pickup_id": id, "quantity_lbs": qty])
        case .deliveryConfirmed(let id):
            return ("delivery_confirmed", ["delivery_id": id])
        case .deliveryCompleted(let id, let qty):
            return ("delivery_completed", ["delivery_id": id, "quantity_lbs": qty])

        case .emailProcessed(let provider, let confidence, let success):
            return ("email_processed", [
                "ai_provider": provider,
                "confidence": confidence,
                "success": success ? 1 : 0
            ])

        case .photoUploaded(let type):
            return ("photo_uploaded", ["photo_type": type])
        }
    }
}
