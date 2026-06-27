//
//  RouteListView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct RouteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PickupRoute.date, order: .reverse) private var routes: [PickupRoute]
    @State private var searchText = ""
    @State private var previewingRoute: PickupRoute?

    var filteredRoutes: [PickupRoute] {
        guard !searchText.isEmpty else { return routes }
        let query = searchText.lowercased()
        return routes.filter { route in
            route.date.formatted(date: .complete, time: .omitted).lowercased().contains(query) ||
            route.status.rawValue.lowercased().contains(query) ||
            route.notes.lowercased().contains(query)
        }
    }

    var body: some View {
        List {
            if routes.isEmpty {
                EmptyRouteState()
            } else if filteredRoutes.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredRoutes) { route in
                    NavigationLink(destination: RouteTrackingView(pickupRoute: route)) {
                        RouteRowView(route: route)
                    }
                    .contextMenu {
                        Button {
                            previewingRoute = route
                        } label: {
                            Label("Preview on Map", systemImage: "map")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if route.status == .planned {
                            Button {
                                route.status = .active
                                try? modelContext.save()
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .tint(.green)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if route.status != .cancelled && route.status != .completed {
                            Button(role: .destructive) {
                                route.status = .cancelled
                                try? modelContext.save()
                            } label: {
                                Label("Cancel", systemImage: "xmark.circle.fill")
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by date, status, or notes")
        .navigationTitle("Pickup Routes")
        .refreshable {}
        .sheet(item: $previewingRoute) { route in
            RoutePreviewSheet(route: route)
        }
    }
}

// MARK: - Empty State

private struct EmptyRouteState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            Text("No Routes Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Generate a schedule from the Dashboard to create today's pickup and delivery routes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                Image(systemName: "sidebar.left")
                    .foregroundColor(.accentColor)
                Text("Open Dashboard → Generate Schedule")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Route Row

struct RouteRowView: View {
    let route: PickupRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(route.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)

                Spacer()

                RouteStatusBadge(status: route.status)
            }

            HStack {
                Label("\(route.pickups.count) pickups", systemImage: "cart.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Label("\(route.deliveries.count) deliveries", systemImage: "house.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                if route.totalDistance > 0 {
                    Text(String(format: "%.1f mi", route.totalDistance))
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            if !route.notes.isEmpty {
                Text(route.notes)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }

            HStack {
                Text("Start: \(route.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()

                Text("End: \(route.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct RouteStatusBadge: View {
    let status: RouteStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .planned: return .orange.opacity(0.2)
        case .active: return .green.opacity(0.2)
        case .completed: return .blue.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch status {
        case .planned: return .orange
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

// MARK: - Route Preview Sheet

struct StopAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let name: String
    let index: Int
    let isPickup: Bool
}

private struct StopRow: View {
    let index: Int
    let name: String
    let address: String
    let time: Date
    let isPickup: Bool
    let notes: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isPickup ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                    .frame(width: 32, height: 32)
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isPickup ? .blue : .green)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !notes.isEmpty {
                    Label(notes, systemImage: "note.text")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

struct RoutePreviewSheet: View {
    let route: PickupRoute
    @Environment(\.dismiss) private var dismiss

    private var stopAnnotations: [StopAnnotation] {
        var annotations: [StopAnnotation] = []
        for (i, pickup) in route.pickups.enumerated() {
            let lat = pickup.foodProvider?.latitude ?? pickup.restaurant?.latitude
            let lon = pickup.foodProvider?.longitude ?? pickup.restaurant?.longitude
            let name = pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Pickup \(i + 1)"
            if let lat, let lon {
                annotations.append(StopAnnotation(
                    id: pickup.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    name: name, index: i + 1, isPickup: true
                ))
            }
        }
        for (i, delivery) in route.deliveries.enumerated() {
            if let lat = delivery.foodBank?.latitude,
               let lon = delivery.foodBank?.longitude {
                let name = delivery.foodBank?.name ?? "Delivery \(i + 1)"
                annotations.append(StopAnnotation(
                    id: delivery.id,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    name: name, index: route.pickups.count + i + 1, isPickup: false
                ))
            }
        }
        return annotations
    }

    var body: some View {
        NavigationStack {
            List {
                if !stopAnnotations.isEmpty {
                    Section {
                        Map {
                            ForEach(stopAnnotations) { stop in
                                Annotation(stop.name, coordinate: stop.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(stop.isPickup ? Color.blue : Color.green)
                                            .frame(width: 28, height: 28)
                                        Text("\(stop.index)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .frame(height: 220)
                        .cornerRadius(10)
                        .listRowInsets(EdgeInsets())
                    }
                }

                Section("Route Summary") {
                    LabeledContent("Total Stops", value: "\(route.pickups.count + route.deliveries.count)")
                    if route.totalDistance > 0 {
                        LabeledContent("Distance", value: String(format: "%.1f mi", route.totalDistance))
                    }
                    if route.estimatedDuration > 0 {
                        LabeledContent("Est. Duration", value: "\(Int(route.estimatedDuration / 60)) min")
                    }
                    LabeledContent(
                        "Window",
                        value: "\(route.startTime.formatted(date: .omitted, time: .shortened)) – \(route.endTime.formatted(date: .omitted, time: .shortened))"
                    )
                }

                if !route.pickups.isEmpty {
                    Section("Pickups (\(route.pickups.count))") {
                        ForEach(Array(route.pickups.enumerated()), id: \.element.id) { i, pickup in
                            StopRow(
                                index: i + 1,
                                name: pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Unknown",
                                address: pickup.foodProvider?.address ?? pickup.restaurant?.address ?? "",
                                time: pickup.scheduledTime,
                                isPickup: true,
                                notes: pickup.notes
                            )
                        }
                    }
                }

                if !route.deliveries.isEmpty {
                    Section("Deliveries (\(route.deliveries.count))") {
                        ForEach(Array(route.deliveries.enumerated()), id: \.element.id) { i, delivery in
                            StopRow(
                                index: route.pickups.count + i + 1,
                                name: delivery.foodBank?.name ?? "Unknown",
                                address: delivery.foodBank?.address ?? "",
                                time: delivery.scheduledTime,
                                isPickup: false,
                                notes: delivery.notes
                            )
                        }
                    }
                }
            }
            .navigationTitle("Route Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PickupRoute.self, configurations: config)
    RouteListView()
        .modelContainer(container)
}
