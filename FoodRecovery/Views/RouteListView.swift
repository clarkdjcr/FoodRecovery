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
    @State private var selectedRoute: PickupRoute?
    
    var body: some View {
        List {
                if routes.isEmpty {
                    ContentUnavailableView(
                        "No Routes",
                        systemImage: "map",
                        description: Text("Routes will appear here once they are created in the Regional Setup.")
                    )
                } else {
                    ForEach(routes) { route in
                        NavigationLink(destination: RouteTrackingView(pickupRoute: route)) {
                            RouteRowView(route: route)
                        }
                    }
                }
            }
            .navigationTitle("Pickup Routes")
            .refreshable {
                // Refresh routes from context if needed
            }
    }
}

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
                Label("\(route.pickups.count)", systemImage: "cart.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Label("\(route.deliveries.count)", systemImage: "house.fill")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Spacer()
                
                if route.totalDistance > 0 {
                    Text(String(format: "%.1f miles", route.totalDistance))
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