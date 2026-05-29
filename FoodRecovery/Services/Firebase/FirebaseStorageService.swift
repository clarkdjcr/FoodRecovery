// FirebaseStorageService.swift
// Handles photo uploads for proof-of-pickup and proof-of-delivery to Firebase Storage.

import FirebaseStorage
import Foundation

final class FirebaseStorageService {
    static let shared = FirebaseStorageService()

    private let storage = Storage.storage()

    private init() {}

    // MARK: - Photo uploads

    func uploadPickupProof(_ data: Data, pickupId: String) async throws -> URL {
        let ref = storage.reference().child("pickups/\(pickupId)/proof.jpg")
        return try await upload(data: data, to: ref)
    }

    func uploadDeliveryProof(_ data: Data, deliveryId: String) async throws -> URL {
        let ref = storage.reference().child("deliveries/\(deliveryId)/proof.jpg")
        return try await upload(data: data, to: ref)
    }

    func uploadRestaurantDonationPhoto(_ data: Data, donationId: String, index: Int) async throws -> URL {
        let ref = storage.reference().child("restaurantDonations/\(donationId)/photo_\(index).jpg")
        return try await upload(data: data, to: ref)
    }

    func uploadDonationReceipt(_ data: Data, donationId: String) async throws -> URL {
        let ref = storage.reference().child("receipts/\(donationId)/receipt.pdf")
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    // MARK: - Deletion

    func deletePhoto(atPath path: String) async throws {
        try await storage.reference().child(path).delete()
    }

    // MARK: - Download

    func downloadData(atPath path: String, maxSize: Int64 = 10 * 1024 * 1024) async throws -> Data {
        try await storage.reference().child(path).data(maxSize: maxSize)
    }

    // MARK: - Private

    private func upload(data: Data, to ref: StorageReference) async throws -> URL {
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }
}
