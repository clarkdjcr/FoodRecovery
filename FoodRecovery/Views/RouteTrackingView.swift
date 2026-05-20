//
//  RouteTrackingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct RouteTrackingView: View {
    let pickupRoute: PickupRoute
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAnnotation: RouteAnnotation?
    @State private var routes: [MKRoute] = []
    @State private var isCalculatingRoute = false
    
    var body: some View {
        VStack {
                MapReader { proxy in
                    Map(position: $cameraPosition, selection: $selectedAnnotation) {
                        // Show current location
                        if let currentLocation = locationManager.currentLocation {
                            Annotation("Current Location", coordinate: currentLocation.coordinate) {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // Show pickup locations
                        ForEach(pickupRoute.pickups, id: \.id) { pickup in
                            if let store = pickup.groceryStore,
                               let lat = store.latitude,
                               let lon = store.longitude {
                                Annotation("Pickup: \(store.name)", 
                                         coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                    PickupAnnotationView(pickup: pickup)
                                }
                                .tag(RouteAnnotation.pickup(pickup))
                            }
                        }
                        
                        // Show delivery locations
                        ForEach(pickupRoute.deliveries, id: \.id) { delivery in
                            if let foodBank = delivery.foodBank,
                               let lat = foodBank.latitude,
                               let lon = foodBank.longitude {
                                Annotation("Delivery: \(foodBank.name)", 
                                         coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                    DeliveryAnnotationView(delivery: delivery)
                                }
                                .tag(RouteAnnotation.delivery(delivery))
                            }
                        }
                        
                        // Show route polylines
                        ForEach(routes.indices, id: \.self) { index in
                            MapPolyline(routes[index].polyline)
                                .stroke(.blue, lineWidth: 5)
                        }
                    }
                    .mapStyle(.standard(elevation: .flat))
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }
                }
                
                // Driver Control Panel
                DriverControlPanel(
                    pickupRoute: pickupRoute,
                    currentStop: currentStop,
                    isCalculatingRoute: isCalculatingRoute,
                    onStartRoute: { startRoute() },
                    onCompleteStop: { markCurrentStopComplete() },
                    onRecalculate: { await calculateOptimizedRoute() }
                )
            }
            .navigationTitle("Route: \(pickupRoute.date.formatted(date: .abbreviated, time: .omitted))")
            .task {
                locationManager.requestLocationPermission()
                await calculateOptimizedRoute()
            }
        }
    
    // MARK: - Private Functions
    
    private var allStops: [Any] {
        var stops: [Any] = []
        stops.append(contentsOf: pickupRoute.pickups)
        stops.append(contentsOf: pickupRoute.deliveries)
        // In a real app, you'd sort these by the optimized order
        return stops
    }
    
    private var currentStop: Any? {
        guard pickupRoute.currentStopIndex < allStops.count else { return nil }
        return allStops[pickupRoute.currentStopIndex]
    }
    
    @MainActor
    private func markCurrentStopComplete() {
        if let pickup = currentStop as? Pickup {
            pickup.status = .completed
            pickup.completedAt = Date()
        } else if let delivery = currentStop as? Delivery {
            delivery.status = .completed
            delivery.completedAt = Date()
        }
        
        pickupRoute.currentStopIndex += 1
        
        if pickupRoute.currentStopIndex >= allStops.count {
            pickupRoute.status = .completed
            pickupRoute.completedAt = Date()
        }
        
        try? modelContext.save()
    }
    
    @MainActor
    private func startRoute() {
        pickupRoute.status = .active
        pickupRoute.currentStopIndex = 0
        try? modelContext.save()
    }

    @MainActor
    private func calculateOptimizedRoute() async {
        isCalculatingRoute = true
        
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Add current location as starting point
        if let currentLocation = locationManager.currentLocation {
            coordinates.append(currentLocation.coordinate)
        }
        
        // Add pickup locations
        for pickup in pickupRoute.pickups {
            if let store = pickup.groceryStore,
               let lat = store.latitude,
               let lon = store.longitude {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        // Add delivery locations
        for delivery in pickupRoute.deliveries {
            if let foodBank = delivery.foodBank,
               let lat = foodBank.latitude,
               let lon = foodBank.longitude {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        
        do {
            routes = try await locationManager.calculateOptimizedRoute(stops: coordinates)
            
            // Update route statistics
            let totalDistance = routes.reduce(0) { $0 + $1.distance }
            let totalTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
            
            pickupRoute.totalDistance = totalDistance / 1609.34 // Convert to miles
            pickupRoute.estimatedDuration = totalTime
            
            try modelContext.save()
            
        } catch {
            print("Failed to calculate route: \(error)")
        }
        
        isCalculatingRoute = false
    }
}

enum RouteAnnotation: Hashable {
    case pickup(Pickup)
    case delivery(Delivery)
}

struct PickupAnnotationView: View {
    let pickup: Pickup
    
    var body: some View {
        VStack {
            Image(systemName: "cart.fill")
                .foregroundColor(.white)
                .font(.headline)
                .padding(8)
                .background(statusColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
        }
    }
    
    private var statusColor: Color {
        switch pickup.status {
        case .proposed: return .orange
        case .confirmed: return .blue
        case .inProgress: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct DeliveryAnnotationView: View {
    let delivery: Delivery
    
    var body: some View {
        VStack {
            Image(systemName: "house.fill")
                .foregroundColor(.white)
                .font(.headline)
                .padding(8)
                .background(statusColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                )
        }
    }
    
    private var statusColor: Color {
        switch delivery.status {
        case .proposed: return .orange
        case .confirmed: return .blue
        case .inProgress: return .yellow
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct DriverControlPanel: View {
    let pickupRoute: PickupRoute
    let currentStop: Any?
    let isCalculatingRoute: Bool
    let onStartRoute: () -> Void
    let onCompleteStop: () -> Void
    let onRecalculate: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(pickupRoute.status == .active ? "Current Stop" : "Route Status")
                        .font(.headline)
                    Text(pickupRoute.status.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
                Spacer()
                
                if pickupRoute.status == .planned {
                    Button(action: onStartRoute) {
                        Label("Start Route", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else if isCalculatingRoute {
                    ProgressView()
                } else {
                    Button(action: {
                        Task { await onRecalculate() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if let stop = currentStop {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: stop is Pickup ? "cart.fill" : "house.fill")
                            .foregroundColor(.blue)
                        Text(stopName(stop))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text(stopAddress(stop))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    HStack(spacing: 12) {
                        Button(action: { openInMaps(stop) }) {
                            Label("Navigate", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: onCompleteStop) {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            } else if pickupRoute.status == .completed {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Route Completed Successfully!")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
        }
        .padding()
        .background(.background)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    private var statusColor: Color {
        switch pickupRoute.status {
        case .planned: return .orange
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
    
    private func stopName(_ stop: Any) -> String {
        if let pickup = stop as? Pickup {
            return pickup.groceryStore?.name ?? pickup.restaurant?.name ?? "Unknown Pickup"
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.name ?? "Unknown Delivery"
        }
        return "Unknown"
    }
    
    private func stopAddress(_ stop: Any) -> String {
        if let pickup = stop as? Pickup {
            return pickup.groceryStore?.address ?? pickup.restaurant?.address ?? ""
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.address ?? ""
        }
        return ""
    }
    
    private func openInMaps(_ stop: Any) {
        let lat: Double
        let lon: Double

        if let pickup = stop as? Pickup {
            lat = pickup.groceryStore?.latitude ?? pickup.restaurant?.latitude ?? 0
            lon = pickup.groceryStore?.longitude ?? pickup.restaurant?.longitude ?? 0
        } else if let delivery = stop as? Delivery {
            lat = delivery.foodBank?.latitude ?? 0
            lon = delivery.foodBank?.longitude ?? 0
        } else {
            return
        }
        
        let url = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PickupRoute.self, configurations: config)
    
    let sampleRoute = PickupRoute(
        date: Date(),
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600)
    )
    
    RouteTrackingView(pickupRoute: sampleRoute)
        .modelContainer(container)
}

