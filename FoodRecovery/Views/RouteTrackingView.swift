//
//  RouteTrackingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import MapKit
import PhotosUI
import SwiftData
import SwiftUI
import TipKit

struct RouteTrackingView: View {
    let pickupRoute: PickupRoute
    @Environment(\.modelContext) private var modelContext
    @State private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedAnnotation: RouteAnnotation?
    @State private var routes: [MKRoute] = []
    @State private var isCalculatingRoute = false
    @State private var capturedPhotoData: Data?
    @State private var showingCompletionSurvey = false
    @State private var showingReorder = false
    @State private var isDriverMode = false

    var body: some View {
        if isDriverMode {
            DriverModeView(pickupRoute: pickupRoute)
        } else {
            VStack {
                MapReader { proxy in
                Map(position: $cameraPosition, selection: $selectedAnnotation) {
                    if let currentLocation = locationManager.currentLocation {
                        Annotation("Current Location", coordinate: currentLocation.coordinate) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }

                    ForEach(pickupRoute.pickups, id: \.id) { pickup in
                        if let store = pickup.foodProvider,
                           let lat = store.latitude,
                           let lon = store.longitude {
                            Annotation("Pickup: \(store.name)",
                                       coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                                PickupAnnotationView(pickup: pickup)
                            }
                            .tag(RouteAnnotation.pickup(pickup))
                        }
                    }

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

            DriverControlPanel(
                pickupRoute: pickupRoute,
                currentStop: currentStop,
                totalStops: allStops.count,
                isCalculatingRoute: isCalculatingRoute,
                timeToNextStop: timeToNextStop,
                totalTimeRemaining: totalTimeRemaining,
                capturedPhotoData: $capturedPhotoData,
                onStartRoute: { startRoute() },
                onCompleteStop: { photoData in markCurrentStopComplete(with: photoData) },
                onRecalculate: { await calculateOptimizedRoute() },
                onNotesChanged: { notes in saveNotes(notes) }
            )
        }
        .navigationTitle("Route: \(pickupRoute.date.formatted(date: .abbreviated, time: .omitted))")
        .task {
            locationManager.requestLocationPermission()
            await calculateOptimizedRoute()
        }
        .sheet(isPresented: $showingCompletionSurvey) {
            RouteCompletionSurveySheet(route: pickupRoute)
        }
        .sheet(isPresented: $showingReorder) {
            StopReorderSheet(route: pickupRoute)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isDriverMode.toggle()
                } label: {
                    Label(isDriverMode ? "Standard View" : "Driver Mode", systemImage: isDriverMode ? "list.bullet" : "car.fill")
                }
            }
            
            if pickupRoute.status == .planned {
                ToolbarItem(placement: .secondaryAction) {
                    Button { showingReorder = true } label: {
                        Label("Reorder Stops", systemImage: "list.number")
                    }
                }
            }
        }
        }
    }

    // MARK: - Private

    private var allStops: [Any] {
        var stops: [Any] = []
        stops.append(contentsOf: pickupRoute.pickups.sorted { $0.sortOrder < $1.sortOrder })
        stops.append(contentsOf: pickupRoute.deliveries.sorted { $0.sortOrder < $1.sortOrder })
        return stops
    }

    private var timeToNextStop: TimeInterval? {
        let idx = pickupRoute.currentStopIndex
        guard pickupRoute.status == .active, idx < routes.count else { return nil }
        return routes[idx].expectedTravelTime
    }

    private var totalTimeRemaining: TimeInterval? {
        let idx = pickupRoute.currentStopIndex
        guard pickupRoute.status == .active, !routes.isEmpty, idx < routes.count else { return nil }
        return routes[idx...].reduce(0) { $0 + $1.expectedTravelTime }
    }

    private var currentStop: Any? {
        guard pickupRoute.currentStopIndex < allStops.count else { return nil }
        return allStops[pickupRoute.currentStopIndex]
    }

    @MainActor
    private func markCurrentStopComplete(with photoData: Data?) {
        if let pickup = currentStop as? Pickup {
            pickup.status = .completed
            pickup.completedAt = Date()
            pickup.proofOfPickupPhoto = photoData
        } else if let delivery = currentStop as? Delivery {
            delivery.status = .completed
            delivery.completedAt = Date()
            delivery.proofOfDeliveryPhoto = photoData
        }

        pickupRoute.currentStopIndex += 1
        capturedPhotoData = nil

        if pickupRoute.currentStopIndex >= allStops.count {
            pickupRoute.status = .completed
            pickupRoute.completedAt = Date()
            showingCompletionSurvey = true
        }

        try? modelContext.save()
    }

    @MainActor
    private func startRoute() {
        pickupRoute.status = .active
        pickupRoute.currentStopIndex = 0
        try? modelContext.save()

        // Schedule pickup reminders now that the route is live
        for pickup in pickupRoute.pickups {
            if let store = pickup.foodProvider {
                NotificationService.shared.schedulePickupReminder(
                    pickupId: pickup.id,
                    storeName: store.name,
                    scheduledTime: pickup.scheduledTime
                )
            }
        }
    }

    @MainActor
    private func calculateOptimizedRoute() async {
        isCalculatingRoute = true
        var coordinates: [CLLocationCoordinate2D] = []

        if let currentLocation = locationManager.currentLocation {
            coordinates.append(currentLocation.coordinate)
        }
        for pickup in pickupRoute.pickups {
            if let store = pickup.foodProvider, let lat = store.latitude, let lon = store.longitude {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        for delivery in pickupRoute.deliveries {
            if let foodBank = delivery.foodBank, let lat = foodBank.latitude, let lon = foodBank.longitude {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }

        do {
            routes = try await locationManager.calculateOptimizedRoute(stops: coordinates)
            let totalDistance = routes.reduce(0) { $0 + $1.distance }
            let totalTime = routes.reduce(0) { $0 + $1.expectedTravelTime }
            pickupRoute.totalDistance = totalDistance / 1609.34
            pickupRoute.estimatedDuration = totalTime
            try modelContext.save()
        } catch {
            print("Failed to calculate route: \(error)")
        }

        isCalculatingRoute = false
    }

    @MainActor
    private func saveNotes(_ notes: String) {
        if let pickup = currentStop as? Pickup {
            pickup.notes = notes
        } else if let delivery = currentStop as? Delivery {
            delivery.notes = notes
        }
        try? modelContext.save()
    }
}

// MARK: - Route Annotations

enum RouteAnnotation: Hashable {
    case pickup(Pickup)
    case delivery(Delivery)
}

struct PickupAnnotationView: View {
    let pickup: Pickup

    var body: some View {
        Image(systemName: "cart.fill")
            .foregroundColor(.white)
            .font(.headline)
            .padding(8)
            .background(statusColor)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
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
        Image(systemName: "house.fill")
            .foregroundColor(.white)
            .font(.headline)
            .padding(8)
            .background(statusColor)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
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

// MARK: - Driver Control Panel

struct DriverControlPanel: View {
    let pickupRoute: PickupRoute
    let currentStop: Any?
    let totalStops: Int
    let isCalculatingRoute: Bool
    let timeToNextStop: TimeInterval?
    let totalTimeRemaining: TimeInterval?
    @Binding var capturedPhotoData: Data?
    let onStartRoute: () -> Void
    let onCompleteStop: (Data?) -> Void
    let onRecalculate: () async -> Void
    let onNotesChanged: (String) -> Void

    @State private var showingPhotoOptions = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isEditingNotes = false
    @State private var draftNotes = ""

    private let notesTip = DriverNotesTip()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack {
                VStack(alignment: .leading) {
                    Text(pickupRoute.status == .active ? "Current Stop" : "Route Status")
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(pickupRoute.status.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(statusColor)
                        if pickupRoute.status == .active {
                            Text("· Stop \(pickupRoute.currentStopIndex + 1) of \(totalStops)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let eta = timeToNextStop {
                                let mins = max(1, Int(eta / 60))
                                Text("~\(mins) min")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    if let remaining = totalTimeRemaining, pickupRoute.status == .active {
                        let totalMins = max(1, Int(remaining / 60))
                        Text("\(totalMins) min remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                    Button {
                        Task { await onRecalculate() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let stop = currentStop {
                VStack(alignment: .leading, spacing: 12) {
                    // Stop name & type
                    HStack {
                        Image(systemName: stop is Pickup ? "cart.fill" : "house.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stopName(stop))
                                .font(.title3)
                                .fontWeight(.bold)
                            if let contact = contactName(for: stop) {
                                Text("Contact: \(contact)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Text(stopAddress(stop))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    // Driver notes (gate codes, special instructions)
                    if isEditingNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            TextEditor(text: $draftNotes)
                                .frame(height: 72)
                                .padding(4)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                            HStack {
                                Button("Cancel") { isEditingNotes = false }
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Save") {
                                    onNotesChanged(draftNotes)
                                    isEditingNotes = false
                                }
                                .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    } else {
                        let notes = stopNotes(stop)
                        Button {
                            draftNotes = notes
                            isEditingNotes = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "note.text")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(notes.isEmpty ? "Add gate code or instructions…" : notes)
                                    .font(.subheadline)
                                    .foregroundColor(notes.isEmpty ? .secondary : .primary)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .popoverTip(notesTip)
                    }

                    // Action buttons row 1: navigate + call + email
                    HStack(spacing: 8) {
                        Button(action: { openInMaps(stop) }) {
                            Label("Navigate", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if let phone = contactPhone(for: stop),
                           let url = URL(string: "tel:\(phone.filter(\.isNumber))") {
                            Link(destination: url) {
                                Label("Call", systemImage: "phone.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        if let email = contactEmail(for: stop),
                           let url = URL(string: "mailto:\(email)") {
                            Link(destination: url) {
                                Label("Email", systemImage: "envelope.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Photo capture row
                    HStack(spacing: 8) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label(
                                capturedPhotoData != nil ? "Photo Added" : "Add Photo Proof",
                                systemImage: capturedPhotoData != nil ? "checkmark.circle.fill" : "camera.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(capturedPhotoData != nil ? .green : .primary)
                        .onChange(of: selectedPhotoItem) { _, item in
                            Task {
                                capturedPhotoData = try? await item?.loadTransferable(type: Data.self)
                            }
                        }

                        if capturedPhotoData != nil {
                            Button(role: .destructive) {
                                capturedPhotoData = nil
                                selectedPhotoItem = nil
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    // Complete button
                    Button(action: { onCompleteStop(capturedPhotoData) }) {
                        Label("Mark Stop Complete", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
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
        .onChange(of: pickupRoute.currentStopIndex) { _, _ in
            isEditingNotes = false
            draftNotes = ""
        }
    }

    // MARK: - Helpers

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
            return pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Unknown Pickup"
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.name ?? "Unknown Delivery"
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

    private func contactName(for stop: Any) -> String? {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.contactName ?? pickup.restaurant?.managerName
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.contactName
        }
        return nil
    }

    private func contactPhone(for stop: Any) -> String? {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.contactPhone ?? pickup.restaurant?.contactPhone
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.contactPhone
        }
        return nil
    }

    private func contactEmail(for stop: Any) -> String? {
        if let pickup = stop as? Pickup {
            return pickup.foodProvider?.contactEmail ?? pickup.restaurant?.contactEmail
        } else if let delivery = stop as? Delivery {
            return delivery.foodBank?.contactEmail
        }
        return nil
    }

    private func stopNotes(_ stop: Any) -> String {
        if let pickup = stop as? Pickup { return pickup.notes }
        if let delivery = stop as? Delivery { return delivery.notes }
        return ""
    }

    private func openInMaps(_ stop: Any) {
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
}

// MARK: - Stop Reorder Sheet

private struct StopReorderSheet: View {
    let route: PickupRoute
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !route.pickups.isEmpty {
                    Section("Pickup Stops") {
                        ForEach(route.pickups.sorted { $0.sortOrder < $1.sortOrder }) { pickup in
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Unknown")
                                        .fontWeight(.medium)
                                    Text(pickup.scheduledTime.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "cart.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                        .onMove { indices, newOffset in reorderPickups(from: indices, to: newOffset) }
                    }
                }

                if !route.deliveries.isEmpty {
                    Section("Delivery Stops") {
                        ForEach(route.deliveries.sorted { $0.sortOrder < $1.sortOrder }) { delivery in
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(delivery.foodBank?.name ?? "Unknown")
                                        .fontWeight(.medium)
                                    Text(delivery.scheduledTime.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "house.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .onMove { indices, newOffset in reorderDeliveries(from: indices, to: newOffset) }
                    }
                }
            }
            #if os(iOS)
            .environment(\.editMode, .constant(.active))
            #endif
            .navigationTitle("Reorder Stops")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func reorderPickups(from source: IndexSet, to destination: Int) {
        var sorted = route.pickups.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, pickup) in sorted.enumerated() { pickup.sortOrder = index }
        try? modelContext.save()
    }

    private func reorderDeliveries(from source: IndexSet, to destination: Int) {
        var sorted = route.deliveries.sorted { $0.sortOrder < $1.sortOrder }
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, delivery) in sorted.enumerated() { delivery.sortOrder = index }
        try? modelContext.save()
    }
}

// MARK: - Route Completion Survey

private struct RouteCompletionSurveySheet: View {
    let route: PickupRoute
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 0
    @State private var selectedIssues: Set<String> = []
    @State private var notes = ""

    private let issues = [
        "All stops went smoothly",
        "Traffic or navigation issues",
        "Pickup not ready on arrival",
        "Food bank unavailable or delayed",
        "Communication issues with contacts",
        "Weather-related delays",
    ]

    var body: some View {
        NavigationStack {
            List {
                Section("How did the route go?") {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(star <= rating ? .yellow : .secondary)
                                .onTapGesture { rating = star }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }

                Section("What happened? (select all that apply)") {
                    ForEach(issues, id: \.self) { issue in
                        Button {
                            if selectedIssues.contains(issue) {
                                selectedIssues.remove(issue)
                            } else {
                                selectedIssues.insert(issue)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedIssues.contains(issue) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedIssues.contains(issue) ? .blue : .secondary)
                                Text(issue)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Additional notes (optional)") {
                    TextField("Any other feedback…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Route Feedback")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { submitFeedback() }
                        .disabled(rating == 0)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func submitFeedback() {
        route.feedbackRating = rating
        route.feedbackIssues = Array(selectedIssues)
        route.feedbackNotes = notes
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PickupRoute.self, configurations: config)
    let sampleRoute = PickupRoute(date: Date(), startTime: Date(), endTime: Date().addingTimeInterval(3600))
    RouteTrackingView(pickupRoute: sampleRoute)
        .modelContainer(container)
}
