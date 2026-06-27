// FoodRecoveryIntents.swift
// App Intents for Siri and Shortcuts integration.
// All intents open the app to a specific section rather than performing
// background operations, avoiding complex cross-process SwiftData access.

import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct FoodRecoveryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowDashboardIntent(),
            phrases: [
                "Open \(.applicationName) Dashboard",
                "Show \(.applicationName) overview",
                "Open food recovery dashboard"
            ],
            shortTitle: "Open Dashboard",
            systemImageName: "chart.bar.fill"
        )
        AppShortcut(
            intent: ShowRoutesIntent(),
            phrases: [
                "Open \(.applicationName) Routes",
                "Show my food recovery routes",
                "Open routes in \(.applicationName)"
            ],
            shortTitle: "Open Routes",
            systemImageName: "map.fill"
        )
        AppShortcut(
            intent: ShowAnalyticsIntent(),
            phrases: [
                "Open \(.applicationName) Analytics",
                "Show food recovery analytics",
                "Open analytics in \(.applicationName)"
            ],
            shortTitle: "Open Analytics",
            systemImageName: "chart.xyaxis.line"
        )
    }
}

// MARK: - Show Dashboard

struct ShowDashboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Dashboard"
    static var description = IntentDescription("Opens the Food Recovery dashboard.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Show Routes

struct ShowRoutesIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Routes"
    static var description = IntentDescription("Opens the pickup routes list.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Show Analytics

struct ShowAnalyticsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Analytics"
    static var description = IntentDescription("Opens the analytics and heat map view.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

// MARK: - Export Impact Report

struct ExportImpactIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Impact Report"
    static var description = IntentDescription("Opens Food Recovery to the impact export screen.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
