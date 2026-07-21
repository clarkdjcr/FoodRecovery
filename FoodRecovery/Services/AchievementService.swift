//
//  AchievementService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 7/12/26.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class AchievementService: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []
    
    private let notificationService = NotificationService.shared
    
    func initializeAchievements(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            achievements = existing
        } else {
            // Create default achievements
            for definition in AchievementDefinition.allAchievements {
                let achievement = Achievement(
                    title: definition.title,
                    description: definition.description,
                    iconName: definition.iconName,
                    category: definition.category,
                    requirementValue: definition.requirementValue
                )
                modelContext.insert(achievement)
                achievements.append(achievement)
            }
            try? modelContext.save()
        }
    }
    
    func updateDonationProgress(modelContext: ModelContext, totalPounds: Double) {
        let descriptor = FetchDescriptor<Achievement>()
        guard let allAchievements = try? modelContext.fetch(descriptor) else { return }
        
        let donationAchievements = allAchievements.filter { $0.category == .donations }
        for achievement in donationAchievements {
            let wasUnlocked = achievement.isUnlocked
            achievement.updateProgress(totalPounds)
            
            if achievement.isUnlocked && !wasUnlocked {
                recentlyUnlocked.append(achievement)
                triggerAchievementNotification(achievement)
            }
        }
        
        try? modelContext.save()
        achievements = allAchievements
    }
    
    func updateRouteProgress(modelContext: ModelContext, completedRoutes: Int) {
        let descriptor = FetchDescriptor<Achievement>()
        guard let allAchievements = try? modelContext.fetch(descriptor) else { return }
        
        let routeAchievements = allAchievements.filter { $0.category == .routes }
        for achievement in routeAchievements {
            let wasUnlocked = achievement.isUnlocked
            achievement.updateProgress(Double(completedRoutes))
            
            if achievement.isUnlocked && !wasUnlocked {
                recentlyUnlocked.append(achievement)
                triggerAchievementNotification(achievement)
            }
        }
        
        try? modelContext.save()
        achievements = allAchievements
    }
    
    func updatePartnershipProgress(modelContext: ModelContext, totalPartners: Int) {
        let descriptor = FetchDescriptor<Achievement>()
        guard let allAchievements = try? modelContext.fetch(descriptor) else { return }
        
        let partnershipAchievements = allAchievements.filter { $0.category == .partnerships }
        for achievement in partnershipAchievements {
            let wasUnlocked = achievement.isUnlocked
            achievement.updateProgress(Double(totalPartners))
            
            if achievement.isUnlocked && !wasUnlocked {
                recentlyUnlocked.append(achievement)
                triggerAchievementNotification(achievement)
            }
        }
        
        try? modelContext.save()
        achievements = allAchievements
    }
    
    func updateSustainabilityProgress(modelContext: ModelContext, totalCO2Diverted: Double) {
        let descriptor = FetchDescriptor<Achievement>()
        guard let allAchievements = try? modelContext.fetch(descriptor) else { return }
        
        let sustainabilityAchievements = allAchievements.filter { $0.category == .sustainability }
        for achievement in sustainabilityAchievements {
            let wasUnlocked = achievement.isUnlocked
            achievement.updateProgress(totalCO2Diverted)
            
            if achievement.isUnlocked && !wasUnlocked {
                recentlyUnlocked.append(achievement)
                triggerAchievementNotification(achievement)
            }
        }
        
        try? modelContext.save()
        achievements = allAchievements
    }
    
    func updateConsistencyProgress(modelContext: ModelContext, consecutiveDays: Int) {
        let descriptor = FetchDescriptor<Achievement>()
        guard let allAchievements = try? modelContext.fetch(descriptor) else { return }
        
        let consistencyAchievements = allAchievements.filter { $0.category == .consistency }
        for achievement in consistencyAchievements {
            let wasUnlocked = achievement.isUnlocked
            achievement.updateProgress(Double(consecutiveDays))
            
            if achievement.isUnlocked && !wasUnlocked {
                recentlyUnlocked.append(achievement)
                triggerAchievementNotification(achievement)
            }
        }
        
        try? modelContext.save()
        achievements = allAchievements
    }
    
    private func triggerAchievementNotification(_ achievement: Achievement) {
        notificationService.scheduleAchievementNotification(
            title: "Achievement Unlocked!",
            body: "You earned: \(achievement.title)"
        )
    }
    
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
    
    func getUnlockedCount() -> Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    func getTotalCount() -> Int {
        achievements.count
    }
    
    func getProgressByCategory() -> [AchievementCategory: Double] {
        var progress: [AchievementCategory: Double] = [:]
        for category in AchievementCategory.allCases {
            let categoryAchievements = achievements.filter { $0.category == category }
            let unlockedCount = categoryAchievements.filter { $0.isUnlocked }.count
            progress[category] = Double(unlockedCount) / Double(categoryAchievements.count)
        }
        return progress
    }
}
