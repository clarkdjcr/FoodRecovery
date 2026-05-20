//
//  EmailService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Foundation

class EmailService {
  private let smtpHost: String
  private let smtpPort: Int
  private let username: String
  private let password: String

  init(smtpHost: String = AppConfiguration.smtpHost, 
       smtpPort: Int = AppConfiguration.smtpPort, 
       username: String = AppConfiguration.smtpUsername, 
       password: String = AppConfiguration.smtpPassword) {
    self.smtpHost = smtpHost
    self.smtpPort = smtpPort
    self.username = username
    self.password = password
  }

  func sendPickupConfirmation(to store: GroceryStore, pickup: Pickup) async throws {
    let subject =
      "Food Donation Pickup Confirmation - \(pickup.scheduledTime.formatted(date: .abbreviated, time: .shortened))"
    let body = createPickupConfirmationBody(store: store, pickup: pickup)

    try await sendEmail(to: store.contactEmail, subject: subject, body: body)
  }

  func sendDeliveryConfirmation(to foodBank: FoodBank, delivery: Delivery) async throws {
    let subject =
      "Food Delivery Confirmation - \(delivery.scheduledTime.formatted(date: .abbreviated, time: .shortened))"
    let body = createDeliveryConfirmationBody(foodBank: foodBank, delivery: delivery)

    try await sendEmail(to: foodBank.contactEmail, subject: subject, body: body)
  }

  func sendRouteConfirmation(to operation: RegionalOperation, route: PickupRoute) async throws {
    let subject =
      "Daily Route Confirmation - \(route.date.formatted(date: .abbreviated, time: .omitted))"
    let body = createRouteConfirmationBody(operation: operation, route: route)

    try await sendEmail(to: operation.contactEmail, subject: subject, body: body)
  }

  private func createPickupConfirmationBody(store: GroceryStore, pickup: Pickup) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let totalQuantity = pickup.totalQuantity
    let donationList = pickup.donations.map { donation in
      "• \(donation.foodType.rawValue.capitalized): \(donation.quantity) lbs"
    }.joined(separator: "\n")

    return """
      Dear \(store.contactName),

      This email confirms your food donation pickup scheduled for:

      Date & Time: \(formatter.string(from: pickup.scheduledTime))
      Location: \(store.name)
      Address: \(store.address)

      Donation Details:
      \(donationList)

      Total Quantity: \(totalQuantity) lbs

      Please ensure the donations are ready for pickup at the scheduled time. If you need to reschedule or have any questions, please contact us immediately.

      Thank you for your generous donation to help reduce food waste in our community!

      Best regards,
      Food Recovery Team
      """
  }

  private func createDeliveryConfirmationBody(foodBank: FoodBank, delivery: Delivery) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let totalQuantity = delivery.totalQuantity
    let donationList = delivery.donations.map { donation in
      "• \(donation.foodType.rawValue.capitalized): \(donation.quantity) lbs"
    }.joined(separator: "\n")

    return """
      Dear \(foodBank.contactName),

      This email confirms your food delivery scheduled for:

      Date & Time: \(formatter.string(from: delivery.scheduledTime))
      Location: \(foodBank.name)
      Address: \(foodBank.address)

      Delivery Details:
      \(donationList)

      Total Quantity: \(totalQuantity) lbs

      Please ensure someone is available to receive the delivery at the scheduled time. If you need to reschedule or have any questions, please contact us immediately.

      Thank you for your partnership in fighting food insecurity!

      Best regards,
      Food Recovery Team
      """
  }

  private func createRouteConfirmationBody(operation: RegionalOperation, route: PickupRoute)
    -> String
  {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    formatter.timeStyle = .short

    let pickupList = route.pickups.map { pickup in
      "• \(pickup.groceryStore?.name ?? "Unknown Store"): \(formatter.string(from: pickup.scheduledTime))"
    }.joined(separator: "\n")

    let deliveryList = route.deliveries.map { delivery in
      "• \(delivery.foodBank?.name ?? "Unknown Food Bank"): \(formatter.string(from: delivery.scheduledTime))"
    }.joined(separator: "\n")

    return """
      Daily Route Confirmation - \(formatter.string(from: route.date))

      Route Details:
      Start Time: \(formatter.string(from: route.startTime))
      End Time: \(formatter.string(from: route.endTime))
      Total Distance: \(String(format: "%.1f", route.totalDistance)) miles
      Estimated Duration: \(String(format: "%.1f", route.estimatedDuration / 3600)) hours

      Pickup Schedule:
      \(pickupList)

      Delivery Schedule:
      \(deliveryList)

      Total Pickup Quantity: \(String(format: "%.1f", route.totalPickupQuantity)) lbs
      Total Delivery Quantity: \(String(format: "%.1f", route.totalDeliveryQuantity)) lbs

      Please review the schedule and confirm all pickups and deliveries.

      Best regards,
      Food Recovery Team
      """
  }

  private func sendEmail(to recipient: String, subject: String, body: String) async throws {
    // For demo purposes, override recipient with configured test email
    let demoRecipient = AppConfiguration.defaultToEmail
    
    // In a real implementation, this would use a proper SMTP library
    // For now, we'll simulate the email sending
    print("Sending email to: \(demoRecipient) (originally to: \(recipient))")
    print("From: \(username)")
    print("Subject: \(subject)")
    print("Body: \(body)")

    // Simulate network delay
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // In a real app, you would implement actual SMTP sending here
    // using libraries like SwiftSMTP or similar
  }
}
