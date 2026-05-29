// FirestoreService.swift
// Central Firestore service: real-time listeners + full CRUD for all models.
// Mirrors SwiftData models to Firestore, enabling cross-device sync.

import Combine
import FirebaseCrashlytics
import FirebaseFirestore
import Foundation

@MainActor
final class FirestoreService: ObservableObject {

    // MARK: - Published state (populated by real-time listeners)

    @Published var operations: [OperationDocument] = []
    @Published var foodBanks: [FoodBankDocument] = []
    @Published var foodProviders: [FoodProviderDocument] = []
    @Published var restaurants: [RestaurantDocument] = []
    @Published var routes: [PickupRouteDocument] = []
    @Published var donations: [DonationDocument] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    // MARK: - Real-time listeners

    func startListening() {
        stopListening()
        let listener = db.collection("operations")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error {
                        self?.handle(error)
                        return
                    }
                    self?.operations = snapshot?.documents.compactMap {
                        try? $0.data(as: OperationDocument.self)
                    } ?? []
                }
            }
        listeners.append(listener)
    }

    func startListeningToOperation(_ operationId: String) {
        let opRef = db.collection("operations").document(operationId)

        let fbListener = opRef.collection("foodBanks")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error { self?.handle(error); return }
                    self?.foodBanks = snapshot?.documents.compactMap {
                        try? $0.data(as: FoodBankDocument.self)
                    } ?? []
                }
            }
        listeners.append(fbListener)

        let fpListener = opRef.collection("foodProviders")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error { self?.handle(error); return }
                    self?.foodProviders = snapshot?.documents.compactMap {
                        try? $0.data(as: FoodProviderDocument.self)
                    } ?? []
                }
            }
        listeners.append(fpListener)

        let restListener = opRef.collection("restaurants")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error { self?.handle(error); return }
                    self?.restaurants = snapshot?.documents.compactMap {
                        try? $0.data(as: RestaurantDocument.self)
                    } ?? []
                }
            }
        listeners.append(restListener)

        let routeListener = opRef.collection("routes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error { self?.handle(error); return }
                    self?.routes = snapshot?.documents.compactMap {
                        try? $0.data(as: PickupRouteDocument.self)
                    } ?? []
                }
            }
        listeners.append(routeListener)

        let donationListener = db.collection("donations")
            .whereField("operationId", isEqualTo: operationId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    if let error = error { self?.handle(error); return }
                    self?.donations = snapshot?.documents.compactMap {
                        try? $0.data(as: DonationDocument.self)
                    } ?? []
                }
            }
        listeners.append(donationListener)
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    // MARK: - Operations

    func saveOperation(_ doc: OperationDocument) async throws {
        try db.collection("operations").document(doc.id).setData(from: doc, merge: true)
    }

    func deleteOperation(_ id: String) async throws {
        try await db.collection("operations").document(id).delete()
    }

    // MARK: - Food Banks

    func saveFoodBank(_ doc: FoodBankDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("foodBanks").document(doc.id).setData(from: doc, merge: true)
    }

    func updateFoodBankUsage(id: String, operationId: String, dailyUsage: Int) async throws {
        try await db.collection("operations").document(operationId)
            .collection("foodBanks").document(id)
            .updateData(["dailyUsage": dailyUsage])
    }

    func updateFoodBankLastDelivery(id: String, operationId: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("foodBanks").document(id)
            .updateData(["lastDelivery": FieldValue.serverTimestamp()])
    }

    func deleteFoodBank(id: String, operationId: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("foodBanks").document(id).delete()
    }

    // MARK: - Food Providers

    func saveFoodProvider(_ doc: FoodProviderDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("foodProviders").document(doc.id).setData(from: doc, merge: true)
    }

    func updateFoodProviderLastPickup(id: String, operationId: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("foodProviders").document(id)
            .updateData(["lastPickup": FieldValue.serverTimestamp()])
    }

    func deleteFoodProvider(id: String, operationId: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("foodProviders").document(id).delete()
    }

    // MARK: - Restaurants

    func saveRestaurant(_ doc: RestaurantDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("restaurants").document(doc.id).setData(from: doc, merge: true)
    }

    func updateRestaurantDonationTotals(
        id: String, operationId: String,
        totalValue: Double, totalPounds: Double, totalTaxBenefit: Double
    ) async throws {
        try await db.collection("operations").document(operationId)
            .collection("restaurants").document(id)
            .updateData([
                "totalDonationsValue": totalValue,
                "totalDonationsPounds": totalPounds,
                "totalTaxBenefit": totalTaxBenefit,
                "lastDonation": FieldValue.serverTimestamp()
            ])
    }

    func deleteRestaurant(id: String, operationId: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("restaurants").document(id).delete()
    }

    // MARK: - Routes

    func saveRoute(_ doc: PickupRouteDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("routes").document(doc.id).setData(from: doc, merge: true)
    }

    func updateRouteStatus(id: String, operationId: String, status: String) async throws {
        var data: [String: Any] = ["status": status]
        if status == "completed" {
            data["completedAt"] = FieldValue.serverTimestamp()
        }
        try await db.collection("operations").document(operationId)
            .collection("routes").document(id).updateData(data)
    }

    func updateRouteStopIndex(id: String, operationId: String, stopIndex: Int) async throws {
        try await db.collection("operations").document(operationId)
            .collection("routes").document(id)
            .updateData(["currentStopIndex": stopIndex])
    }

    func savePickup(_ doc: PickupDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("routes").document(doc.routeId)
            .collection("pickups").document(doc.id).setData(from: doc, merge: true)
    }

    func updatePickupStatus(id: String, routeId: String, operationId: String, status: String) async throws {
        var data: [String: Any] = ["status": status]
        if status == "completed" {
            data["completedAt"] = FieldValue.serverTimestamp()
            data["actualTime"] = FieldValue.serverTimestamp()
        } else if status == "confirmed" {
            data["confirmedAt"] = FieldValue.serverTimestamp()
        }
        try await db.collection("operations").document(operationId)
            .collection("routes").document(routeId)
            .collection("pickups").document(id).updateData(data)
    }

    func updatePickupProofPhoto(id: String, routeId: String, operationId: String, url: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("routes").document(routeId)
            .collection("pickups").document(id)
            .updateData(["proofPhotoURL": url])
    }

    func saveDelivery(_ doc: DeliveryDocument) async throws {
        try db.collection("operations").document(doc.operationId)
            .collection("routes").document(doc.routeId)
            .collection("deliveries").document(doc.id).setData(from: doc, merge: true)
    }

    func updateDeliveryStatus(id: String, routeId: String, operationId: String, status: String) async throws {
        var data: [String: Any] = ["status": status]
        if status == "completed" {
            data["completedAt"] = FieldValue.serverTimestamp()
            data["actualTime"] = FieldValue.serverTimestamp()
        } else if status == "confirmed" {
            data["confirmedAt"] = FieldValue.serverTimestamp()
        }
        try await db.collection("operations").document(operationId)
            .collection("routes").document(routeId)
            .collection("deliveries").document(id).updateData(data)
    }

    func updateDeliveryProofPhoto(id: String, routeId: String, operationId: String, url: String) async throws {
        try await db.collection("operations").document(operationId)
            .collection("routes").document(routeId)
            .collection("deliveries").document(id)
            .updateData(["proofPhotoURL": url])
    }

    // MARK: - Donations

    func saveDonation(_ doc: DonationDocument) async throws {
        try db.collection("donations").document(doc.id).setData(from: doc, merge: true)
    }

    func updateDonationStatus(id: String, status: String) async throws {
        try await db.collection("donations").document(id).updateData(["status": status])
    }

    func verifyDonation(id: String) async throws {
        try await db.collection("donations").document(id).updateData(["isVerified": true])
    }

    // MARK: - Restaurant Donations

    func saveRestaurantDonation(_ doc: RestaurantDonationDocument) async throws {
        try db.collection("restaurantDonations").document(doc.id).setData(from: doc, merge: true)
    }

    func updateRestaurantDonationReceipt(id: String, receiptURL: String) async throws {
        try await db.collection("restaurantDonations").document(id)
            .updateData(["donationReceiptGenerated": true, "donationReceiptURL": receiptURL])
    }

    // MARK: - Bulk sync (SwiftData → Firestore on first launch or data migration)

    func syncOperation(_ model: RegionalOperation) async {
        do {
            let doc = OperationDocument(from: model)
            try await saveOperation(doc)

            for bank in model.foodBanks {
                try await saveFoodBank(FoodBankDocument(from: bank, operationId: doc.id))
            }
            for provider in model.foodProviders {
                try await saveFoodProvider(FoodProviderDocument(from: provider, operationId: doc.id))
            }
            for restaurant in model.restaurants {
                try await saveRestaurant(RestaurantDocument(from: restaurant, operationId: doc.id))
            }
            for route in model.pickupRoutes {
                let routeDoc = PickupRouteDocument(from: route, operationId: doc.id)
                try await saveRoute(routeDoc)
                for pickup in route.pickups {
                    try await savePickup(PickupDocument(from: pickup, routeId: routeDoc.id, operationId: doc.id))
                }
                for delivery in route.deliveries {
                    try await saveDelivery(DeliveryDocument(from: delivery, routeId: routeDoc.id, operationId: doc.id))
                }
            }
        } catch {
            handle(error)
        }
    }

    // MARK: - Error handling

    private func handle(_ error: Error) {
        errorMessage = error.localizedDescription
        Crashlytics.crashlytics().record(error: error)
    }
}
