//
//  RouteListView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import SwiftData
import SwiftUI

struct RouteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PickupRoute.date, order: .reverse) private var routes: [PickupRoute]
    @State private var searchText = ""

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

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PickupRoute.self, configurations: config)
    RouteListView()
        .modelContainer(container)
}
