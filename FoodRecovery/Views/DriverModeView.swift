//
//  DriverModeView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 7/12/26.
//

import CoreLocation
import MapKit
import PhotosUI
import SwiftData
import SwiftUI

struct DriverModeView: View {
    let pickupRoute: PickupRoute
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var capturedPhotoData: Data?
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingNavigation = false
    
    private var currentStop: Any? {
        let allStops: [Any] = pickupRoute.pickups + pickupRoute.deliveries
        guard pickupRoute.currentStopIndex < allStops.count else { return nil }
        return allStops[pickupRoute.currentStopIndex]
    }
    
    private var allStops: [Any] {
        pickupRoute.pickups + pickupRoute.deliveries
    }
    
    var body: some View {
        ZStack {
            // Full-screen map
            Map(position: $cameraPosition) {
                if let currentLocation = locationManager.currentLocation {
                    Annotation("You", coordinate: currentLocation.coordinate) {
                        Circle()
                            .fill(.blue)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                    }
                }
                
                ForEach(pickupRoute.pickups, id: \.id) { pickup in
                    if let store = pickup.foodProvider,
                       let lat = store.latitude, let lon = store.longitude {
                        Annotation(store.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            DriverStopAnnotation(
                                type: .pickup,
                                status: pickup.status,
                                isCurrent: currentStop as? Pickup == pickup
                            )
                        }
                    }
                }
                
                ForEach(pickupRoute.deliveries, id: \.id) { delivery in
                    if let foodBank = delivery.foodBank,
                       let lat = foodBank.latitude, let lon = foodBank.longitude {
                        Annotation(foodBank.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            DriverStopAnnotation(
                                type: .delivery,
                                status: PickupStatus(rawValue: delivery.status.rawValue) ?? .proposed,
                                isCurrent: currentStop as? Delivery == delivery
                            )
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea()
            
            // Top status bar
            VStack {
                DriverStatusBar(
                    route: pickupRoute,
                    currentStopIndex: pickupRoute.currentStopIndex,
                    totalStops: allStops.count
                )
                .padding(.top, 50)
                Spacer()
            }
            
            // Bottom control panel
            VStack {
                Spacer()
                if let stop = currentStop {
                    DriverStopCard(
                        stop: stop,
                        photoData: $capturedPhotoData,
                        onComplete: { completeStop() },
                        onNavigate: { openNavigation() },
                        onCall: { callContact() }
                    )
                    .padding()
                } else if pickupRoute.status == .completed {
                    DriverCompletionCard(onDismiss: { dismiss() })
                        .padding()
                }
            }
        }
        .task {
            locationManager.requestLocationPermission()
            if pickupRoute.status == .planned {
                startRoute()
            }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("Select Photo")
            }
            .onChange(of: selectedPhotoItem) { _, item in
                Task {
                    capturedPhotoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        }
    }
    
    @MainActor
    private func startRoute() {
        pickupRoute.status = .active
        pickupRoute.currentStopIndex = 0
        try? modelContext.save()
    }
    
    @MainActor
    private func completeStop() {
        if let pickup = currentStop as? Pickup {
            pickup.status = .completed
            pickup.completedAt = Date()
            pickup.proofOfPickupPhoto = capturedPhotoData
        } else if let delivery = currentStop as? Delivery {
            delivery.status = .completed
            delivery.completedAt = Date()
            delivery.proofOfDeliveryPhoto = capturedPhotoData
        }
        
        pickupRoute.currentStopIndex += 1
        capturedPhotoData = nil
        
        if pickupRoute.currentStopIndex >= allStops.count {
            pickupRoute.status = .completed
            pickupRoute.completedAt = Date()
        }
        
        try? modelContext.save()
    }
    
    private func openNavigation() {
        guard let stop = currentStop else { return }
        
        let lat: Double
        let lon: Double
        
        if let pickup = stop as? Pickup {
            lat = pickup.foodProvider?.latitude ?? pickup.restaurant?.latitude ?? 0
            lon = pickup.foodProvider?.longitude ?? pickup.restaurant?.longitude ?? 0
        } else if let delivery = stop as? Delivery {
            lat = delivery.foodBank?.latitude ?? 0
            lon = delivery.foodBank?.longitude ?? 0
        } else {
            return
        }
        
        guard let url = URL(string: "https://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") else { return }
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
    
    private func callContact() {
        guard let stop = currentStop else { return }
        
        let phone: String?
        if let pickup = stop as? Pickup {
            phone = pickup.foodProvider?.contactPhone ?? pickup.restaurant?.contactPhone
        } else if let delivery = stop as? Delivery {
            phone = delivery.foodBank?.contactPhone
        } else {
            phone = nil
        }
        
        guard let phone = phone,
              let url = URL(string: "tel:\(phone.filter(\.isNumber))") else { return }
        #if canImport(UIKit)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Driver Status Bar

struct DriverStatusBar: View {
    let route: PickupRoute
    let currentStopIndex: Int
    let totalStops: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Stop \(currentStopIndex + 1) of \(totalStops)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(route.status.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(route.totalDistance, specifier: "%.1f") mi")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(Int(route.estimatedDuration / 60)) min")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding()
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
                .shadow(color: .black.opacity(0.3), radius: 10)
        )
        .padding(.horizontal)
    }
}

// MARK: - Driver Stop Card

struct DriverStopCard: View {
    let stop: Any
    @Binding var photoData: Data?
    let onComplete: () -> Void
    let onNavigate: () -> Void
    let onCall: () -> Void
    
    @State private var showingPhotoPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Stop info
            HStack {
                Image(systemName: stop is Pickup ? "cart.fill" : "house.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stopName(stop))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(stopAddress(stop))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Large action buttons
            HStack(spacing: 12) {
                DriverActionButton(
                    title: "Navigate",
                    icon: "location.fill",
                    color: .blue,
                    action: onNavigate
                )
                
                if let phone = contactPhone(stop) {
                    DriverActionButton(
                        title: "Call",
                        icon: "phone.fill",
                        color: .green,
                        action: onCall
                    )
                }
            }
            
            // Photo capture
            PhotosPicker(selection: .constant(nil), matching: .images) {
                HStack {
                    Image(systemName: photoData != nil ? "checkmark.circle.fill" : "camera.fill")
                        .font(.title2)
                    Text(photoData != nil ? "Photo Added" : "Add Photo Proof")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(photoData != nil ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(photoData != nil ? .green : .primary)
                .cornerRadius(12)
            }
            
            // Complete button
            Button(action: onComplete) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                    Text("Complete Stop")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
    }
    
    private func stopName(_ stop: Any) -> String {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Unknown"
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.name ?? "Unknown"
        }
        return "Unknown"
    }
    
    private func stopAddress(_ stop: Any) -> String {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.address ?? pickup.restaurant?.address ?? ""
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.address ?? ""
        }
        return ""
    }
    
    private func contactPhone(_ stop: Any) -> String? {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.contactPhone ?? pickup.restaurant?.contactPhone
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.contactPhone
        }
        return nil
    }
}

// MARK: - Driver Action Button

struct DriverActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Driver Completion Card

struct DriverCompletionCard: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Route Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("All stops have been completed successfully")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onDismiss) {
                Text("Exit Driver Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
    }
}

// MARK: - Driver Stop Annotation

struct DriverStopAnnotation: View {
    enum StopType {
        case pickup
        case delivery
    }
    
    let type: StopType
    let status: PickupStatus
    let isCurrent: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: isCurrent ? 50 : 40, height: isCurrent ? 50 : 40)
            
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: isCurrent ? 30 : 24, height: isCurrent ? 30 : 24)
        }
        .overlay(
            Circle()
                .stroke(.white, lineWidth: isCurrent ? 4 : 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 5)
    }
    
    private var iconName: String {
        switch type {
        case .pickup: return "cart.fill"
        case .delivery: return "house.fill"
        }
    }
    
    private var backgroundColor: Color {
        if isCurrent { return .blue }
        
        switch status {
        case .completed: return .green
        case .inProgress: return .orange
        default: return .gray
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PickupRoute.self, configurations: config)
    let sampleRoute = PickupRoute(date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3600))
    sampleRoute.status = .active
    
    return DriverModeView(pickupRoute: sampleRoute)
        .modelContainer(container)
}
