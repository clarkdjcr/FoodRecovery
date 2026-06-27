// AchievementsView.swift
// Milestone badge grid computed from SwiftData operation totals.

import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query private var operations: [RegionalOperation]

    private var operation: RegionalOperation? {
        operations.first(where: { $0.isActive }) ?? operations.first
    }

    var body: some View {
        if let operation {
            AchievementGrid(operation: operation)
        } else {
            ContentUnavailableView(
                "No Operation",
                systemImage: "trophy.fill",
                description: Text("Set up a regional operation to track achievements.")
            )
            .navigationTitle("Achievements")
        }
    }
}

// MARK: - Badge definitions

private struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    let progress: Double   // 0.0 – 1.0
    let threshold: String  // human-readable goal
}

// MARK: - Grid view

private struct AchievementGrid: View {
    let operation: RegionalOperation

    private var stats: (routes: Int, lbs: Double, banks: Int, providers: Int) {
        let routes = operation.pickupRoutes.filter { $0.status == .completed }.count
        let lbs = operation.pickupRoutes
            .filter { $0.status == .completed }
            .reduce(0.0) { $0 + $1.totalPickupQuantity }
        let banks = operation.foodBanks.count
        let providers = operation.foodProviders.count
        return (routes, lbs, banks, providers)
    }

    private var badges: [Badge] {
        let s = stats
        return [
            Badge(
                title: "First Route",
                description: "Complete your very first pickup route",
                icon: "flag.checkered",
                color: .green,
                isUnlocked: s.routes >= 1,
                progress: min(Double(s.routes), 1),
                threshold: "1 route"
            ),
            Badge(
                title: "100 lbs",
                description: "Recover 100 lbs of food",
                icon: "scalemass.fill",
                color: .blue,
                isUnlocked: s.lbs >= 100,
                progress: min(s.lbs / 100, 1),
                threshold: "100 lbs"
            ),
            Badge(
                title: "1,000 lbs",
                description: "Recover 1,000 lbs of food",
                icon: "scalemass.fill",
                color: .cyan,
                isUnlocked: s.lbs >= 1000,
                progress: min(s.lbs / 1000, 1),
                threshold: "1,000 lbs"
            ),
            Badge(
                title: "10,000 lbs",
                description: "Recover 10,000 lbs of food",
                icon: "trophy.fill",
                color: .orange,
                isUnlocked: s.lbs >= 10000,
                progress: min(s.lbs / 10000, 1),
                threshold: "10,000 lbs"
            ),
            Badge(
                title: "50,000 lbs",
                description: "Recover 50,000 lbs of food",
                icon: "trophy.fill",
                color: .yellow,
                isUnlocked: s.lbs >= 50000,
                progress: min(s.lbs / 50000, 1),
                threshold: "50,000 lbs"
            ),
            Badge(
                title: "Network Builder",
                description: "Partner with 3 food banks",
                icon: "house.fill",
                color: .teal,
                isUnlocked: s.banks >= 3,
                progress: min(Double(s.banks) / 3, 1),
                threshold: "3 food banks"
            ),
            Badge(
                title: "Community Hub",
                description: "Enroll 5 food providers",
                icon: "cart.fill",
                color: .mint,
                isUnlocked: s.providers >= 5,
                progress: min(Double(s.providers) / 5, 1),
                threshold: "5 providers"
            ),
            Badge(
                title: "Route Runner",
                description: "Complete 10 routes",
                icon: "map.fill",
                color: .indigo,
                isUnlocked: s.routes >= 10,
                progress: min(Double(s.routes) / 10, 1),
                threshold: "10 routes"
            ),
            Badge(
                title: "Road Warrior",
                description: "Complete 50 routes",
                icon: "car.fill",
                color: .purple,
                isUnlocked: s.routes >= 50,
                progress: min(Double(s.routes) / 50, 1),
                threshold: "50 routes"
            ),
            Badge(
                title: "Eco Hero",
                description: "Divert 5,000 lbs from landfill (saves ~8,750 lbs CO₂)",
                icon: "leaf.fill",
                color: .green,
                isUnlocked: s.lbs >= 5000,
                progress: min(s.lbs / 5000, 1),
                threshold: "5,000 lbs diverted"
            ),
            Badge(
                title: "Hunger Fighter",
                description: "Recover 25,000 lbs of food",
                icon: "heart.fill",
                color: .red,
                isUnlocked: s.lbs >= 25000,
                progress: min(s.lbs / 25000, 1),
                threshold: "25,000 lbs"
            ),
            Badge(
                title: "Super Network",
                description: "Partner with 10 food banks",
                icon: "network",
                color: .cyan,
                isUnlocked: s.banks >= 10,
                progress: min(Double(s.banks) / 10, 1),
                threshold: "10 food banks"
            ),
        ]
    }

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 16)
    ]

    private var unlocked: [Badge] { badges.filter { $0.isUnlocked } }
    private var locked: [Badge] { badges.filter { !$0.isUnlocked } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary header
                HStack(spacing: 16) {
                    statPill(value: unlocked.count, label: "Unlocked", color: .green)
                    statPill(value: locked.count, label: "Remaining", color: .secondary)
                    Spacer()
                }
                .padding(.horizontal)

                if !unlocked.isEmpty {
                    sectionHeader("Earned", icon: "checkmark.seal.fill", color: .green)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(unlocked) { badge in
                            BadgeCell(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }

                if !locked.isEmpty {
                    sectionHeader("In Progress", icon: "lock.fill", color: .secondary)
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(locked) { badge in
                            BadgeCell(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Achievements")
    }

    private func statPill(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color == .secondary ? .secondary : color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color == .secondary ? Color.secondary.opacity(0.1) : color.opacity(0.1))
        .cornerRadius(10)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
        }
        .padding(.horizontal)
    }
}

// MARK: - Badge cell

private struct BadgeCell: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? badge.color.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: badge.icon)
                    .font(.system(size: 28))
                    .foregroundColor(badge.isUnlocked ? badge.color : .secondary)
                    .opacity(badge.isUnlocked ? 1 : 0.4)
            }

            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(badge.isUnlocked ? .primary : .secondary)

                Text(badge.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            if !badge.isUnlocked {
                VStack(spacing: 3) {
                    ProgressView(value: badge.progress)
                        .tint(badge.color)
                    let pct = String(format: "%.0f", badge.progress * 100)
                    Text("\(pct)% — \(badge.threshold)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(badge.isUnlocked
                      ? badge.color.opacity(0.07)
                      : Color.secondary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(badge.isUnlocked ? badge.color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}
