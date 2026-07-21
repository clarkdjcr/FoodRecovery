//
//  NotificationService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private init() {}

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // Fires 30 minutes before the scheduled pickup time
    func schedulePickupReminder(pickupId: UUID, storeName: String, scheduledTime: Date) {
        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -30, to: scheduledTime),
              triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Pickup in 30 Minutes"
        content.body = "Head to \(storeName) — pickup at \(scheduledTime.formatted(date: .omitted, time: .shortened))"
        content.sound = .default

        schedule(content: content, at: triggerDate, id: "pickup_\(pickupId.uuidString)")
    }

    // Fires 2 hours before the donation expires
    func scheduleDonationExpiryAlert(donationId: UUID, description: String, storeName: String, expiryDate: Date) {
        guard let triggerDate = Calendar.current.date(byAdding: .hour, value: -2, to: expiryDate),
              triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Donation Expiring Soon"
        content.body = "\(description) from \(storeName) expires at \(expiryDate.formatted(date: .omitted, time: .shortened))"
        content.sound = .default

        schedule(content: content, at: triggerDate, id: "expiry_\(donationId.uuidString)")
    }

    // Fires 15 minutes after the planned start time if the route hasn't been activated
    func scheduleRouteOverdueAlert(routeId: UUID, startTime: Date) {
        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: 15, to: startTime),
              triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Route Not Started"
        content.body = "A route planned for \(startTime.formatted(date: .omitted, time: .shortened)) has not been activated yet."
        content.sound = .default

        schedule(content: content, at: triggerDate, id: "overdue_\(routeId.uuidString)")
    }

    // Fires immediately when an achievement is unlocked
    func scheduleAchievementNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification scheduling error: \(error)") }
        }
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Private

    private func schedule(content: UNMutableNotificationContent, at date: Date, id: String) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification scheduling error: \(error)") }
        }
    }
}
