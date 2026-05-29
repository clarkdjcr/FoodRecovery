// RealtimeRouteService.swift
// Uses Firebase Realtime Database for live route tracking (GPS, stop progress).
// Realtime DB is ideal for high-frequency location writes (vs. Firestore cost/latency).

import FirebaseDatabase
import Foundation

// MARK: - Data model for the Realtime DB

struct LiveRouteState: Codable {
    var routeId: String
    var driverId: String
    var driverName: String
    var latitude: Double
    var longitude: Double
    var currentStopIndex: Int
    var status: String          // "active", "completed", "paused"
    var lastUpdatedEpoch: Double  // Unix timestamp

    static func initial(routeId: String, driverId: String, driverName: String) -> LiveRouteState {
        LiveRouteState(
            routeId: routeId,
            driverId: driverId,
            driverName: driverName,
            latitude: 0,
            longitude: 0,
            currentStopIndex: 0,
            status: "active",
            lastUpdatedEpoch: Date().timeIntervalSince1970
        )
    }
}

// MARK: - Service

@MainActor
final class RealtimeRouteService: ObservableObject {

    @Published var trackedRoutes: [String: LiveRouteState] = [:]

    private let ref = Database.database().reference().child("routeTracking")
    private var observerHandles: [String: DatabaseHandle] = [:]

    // MARK: - Driver-side: publish location

    func startRoute(routeId: String, driverId: String, driverName: String) {
        let state = LiveRouteState.initial(routeId: routeId, driverId: driverId, driverName: driverName)
        writeState(state, routeId: routeId)
    }

    func updateLocation(
        routeId: String, driverId: String, driverName: String,
        latitude: Double, longitude: Double,
        currentStopIndex: Int, status: String = "active"
    ) {
        let state = LiveRouteState(
            routeId: routeId,
            driverId: driverId,
            driverName: driverName,
            latitude: latitude,
            longitude: longitude,
            currentStopIndex: currentStopIndex,
            status: status,
            lastUpdatedEpoch: Date().timeIntervalSince1970
        )
        writeState(state, routeId: routeId)
    }

    func completeRoute(routeId: String, driverId: String, driverName: String) {
        let state = LiveRouteState(
            routeId: routeId,
            driverId: driverId,
            driverName: driverName,
            latitude: 0,
            longitude: 0,
            currentStopIndex: 0,
            status: "completed",
            lastUpdatedEpoch: Date().timeIntervalSince1970
        )
        writeState(state, routeId: routeId)
    }

    // MARK: - Dispatcher-side: observe routes

    func observe(routeId: String) {
        guard observerHandles[routeId] == nil else { return }
        let handle = ref.child(routeId).observe(.value) { [weak self] snapshot in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let value = snapshot.value as? [String: Any],
                   let data = try? JSONSerialization.data(withJSONObject: value),
                   let state = try? JSONDecoder().decode(LiveRouteState.self, from: data) {
                    self.trackedRoutes[routeId] = state
                }
            }
        }
        observerHandles[routeId] = handle
    }

    func stopObserving(routeId: String) {
        if let handle = observerHandles.removeValue(forKey: routeId) {
            ref.child(routeId).removeObserver(withHandle: handle)
            trackedRoutes.removeValue(forKey: routeId)
        }
    }

    func stopAllObservers() {
        for (routeId, handle) in observerHandles {
            ref.child(routeId).removeObserver(withHandle: handle)
        }
        observerHandles.removeAll()
        trackedRoutes.removeAll()
    }

    // MARK: - Cleanup

    func clearRouteData(routeId: String) {
        ref.child(routeId).removeValue()
    }

    // MARK: - Private

    private func writeState(_ state: LiveRouteState, routeId: String) {
        guard let data = try? JSONEncoder().encode(state),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        ref.child(routeId).setValue(dict)
    }
}
