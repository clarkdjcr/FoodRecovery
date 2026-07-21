//
//  Achievement.swift
//  FoodRecovery
//
//  Created by Donald Clark on 7/12/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Achievement {
    var id: UUID
    var title: String
    var achievementDescription: String
    var iconName: String
    var category: AchievementCategory
    var requirementValue: Double
    var currentValue: Double
    var isUnlocked: Bool
    var unlockedAt: Date?
    var createdAt: Date
    
    init(title: String, description: String, iconName: String, category: AchievementCategory, requirementValue: Double) {
        self.id = UUID()
        self.title = title
        self.achievementDescription = description
        self.iconName = iconName
        self.category = category
        self.requirementValue = requirementValue
        self.currentValue = 0
        self.isUnlocked = false
        self.createdAt = Date()
    }
    
    var progress: Double {
        min(currentValue / requirementValue, 1.0)
    }
    
    func updateProgress(_ newValue: Double) {
        currentValue = newValue
        if currentValue >= requirementValue && !isUnlocked {
            isUnlocked = true
            unlockedAt = Date()
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case donations = "Donations"
    case routes = "Routes"
    case partnerships = "Partnerships"
    case sustainability = "Sustainability"
    case consistency = "Consistency"
    
    var iconName: String {
        switch self {
        case .donations: return "gift.fill"
        case .routes: return "truck.fill"
        case .partnerships: return "handshake.fill"
        case .sustainability: return "leaf.fill"
        case .consistency: return "calendar.badge.checkmark"
        }
    }
    
    var color: Color {
        switch self {
        case .donations: return .blue
        case .routes: return .green
        case .partnerships: return .purple
        case .sustainability: return .teal
        case .consistency: return .orange
        }
    }
}

// MARK: - Achievement Definitions

struct AchievementDefinition {
    let title: String
    let description: String
    let iconName: String
    let category: AchievementCategory
    let requirementValue: Double
    
    static let allAchievements: [AchievementDefinition] = [
        // Donation Milestones
        AchievementDefinition(
            title: "First Donation",
            description: "Complete your first food donation",
            iconName: "star.fill",
            category: .donations,
            requirementValue: 1
        ),
        AchievementDefinition(
            title: "100 Pounds Club",
            description: "Rescue 100 pounds of food",
            iconName: "scalemass.fill",
            category: .donations,
            requirementValue: 100
        ),
        AchievementDefinition(
            title: "500 Pounds Club",
            description: "Rescue 500 pounds of food",
            iconName: "scalemass.fill",
            category: .donations,
            requirementValue: 500
        ),
        AchievementDefinition(
            title: "Ton of Good",
            description: "Rescue 2,000 pounds of food",
            iconName: "scalemass.fill",
            category: .donations,
            requirementValue: 2000
        ),
        
        // Route Milestones
        AchievementDefinition(
            title: "First Route",
            description: "Complete your first pickup route",
            iconName: "map.fill",
            category: .routes,
            requirementValue: 1
        ),
        AchievementDefinition(
            title: "Route Master",
            description: "Complete 10 routes",
            iconName: "truck.fill",
            category: .routes,
            requirementValue: 10
        ),
        AchievementDefinition(
            title: "Fleet Captain",
            description: "Complete 50 routes",
            iconName: "truck.box.fill",
            category: .routes,
            requirementValue: 50
        ),
        
        // Partnership Milestones
        AchievementDefinition(
            title: "First Partner",
            description: "Onboard your first food bank or store",
            iconName: "person.badge.plus",
            category: .partnerships,
            requirementValue: 1
        ),
        AchievementDefinition(
            title: "Growing Network",
            description: "Partner with 5 organizations",
            iconName: "person.2.fill",
            category: .partnerships,
            requirementValue: 5
        ),
        AchievementDefinition(
            title: "Community Builder",
            description: "Partner with 10 organizations",
            iconName: "person.3.fill",
            category: .partnerships,
            requirementValue: 10
        ),
        
        // Sustainability Milestones
        AchievementDefinition(
            title: "Carbon Conscious",
            description: "Divert 10 kg of CO2 emissions",
            iconName: "leaf.fill",
            category: .sustainability,
            requirementValue: 10
        ),
        AchievementDefinition(
            title: "Eco Warrior",
            description: "Divert 50 kg of CO2 emissions",
            iconName: "leaf.circle.fill",
            category: .sustainability,
            requirementValue: 50
        ),
        AchievementDefinition(
            title: "Planet Saver",
            description: "Divert 200 kg of CO2 emissions",
            iconName: "globe.americas.fill",
            category: .sustainability,
            requirementValue: 200
        ),
        
        // Consistency Milestones
        AchievementDefinition(
            title: "Week Warrior",
            description: "Complete routes for 7 consecutive days",
            iconName: "calendar",
            category: .consistency,
            requirementValue: 7
        ),
        AchievementDefinition(
            title: "Monthly Champion",
            description: "Complete routes for 30 consecutive days",
            iconName: "calendar.badge",
            category: .consistency,
            requirementValue: 30
        ),
    ]
}
