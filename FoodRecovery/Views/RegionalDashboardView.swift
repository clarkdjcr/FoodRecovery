//
//  RegionalDashboardView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import Charts
import SwiftData
import SwiftUI

struct RegionalDashboardView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject var authService: FirebaseAuthService
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var selectedOperation: RegionalOperation?
  @State private var selectedDate = Date()
  @State private var showingScheduleGeneration = false
  @State private var showingAddFoodBank = false
  @State private var showingAddStore = false
  @State private var showingEmailProcessing = false


  var body: some View {
    VStack {
        if let operation = selectedOperation {
          ScrollView {
            VStack(spacing: 20) {
              // Personalized Greeting with Daily Summary
              GreetingCard(operation: operation, date: selectedDate, operatorName: authService.displayName)

              // Quick Actions
              QuickActionsCard(
                operation: operation,
                onGenerateSchedule: { showingScheduleGeneration = true },
                onAddFoodBank: { showingAddFoodBank = true },
                onAddStore: { showingAddStore = true },
                onProcessEmails: { showingEmailProcessing = true }
              )

              // Urgent Alerts
              UrgentAlertsCard(operation: operation)

              // Operation Overview
              OperationOverviewCard(operation: operation)

              // Today's Schedule
              TodaysScheduleCard(operation: operation, date: selectedDate)

              // Statistics
              StatisticsCard(operation: operation)

              // Weekly Trend
              WeeklyTrendCard(operation: operation)

              // Sustainability Impact
              SustainabilityImpactCard(operation: operation)

              // Food Bank Status
              FoodBankStatusCard(operation: operation)

              // Recent Activity
              RecentActivityCard(operation: operation)
            }
            .padding()
          }
        } else {
          VStack {
            Image(systemName: "truck.box")
              .font(.system(size: 60))
              .foregroundColor(.gray)

            Text("Select a Regional Operation")
              .font(.title2)
              .foregroundColor(.gray)

            Text("Choose an operation from the list to view the dashboard")
              .font(.body)
              .foregroundColor(AppTheme.Colors.textSecondary)
              .multilineTextAlignment(.center)
          }
          .padding()
        }
      }
      .navigationTitle("Regional Dashboard")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Picker("Operation", selection: $selectedOperation) {
            Text("Select Operation").tag(nil as RegionalOperation?)
            ForEach(viewModel.operations, id: \.id) { operation in
              Text(operation.name).tag(operation as RegionalOperation?)
            }
          }
          .pickerStyle(MenuPickerStyle())
        }

        ToolbarItem(placement: .secondaryAction) {
          Button("Generate Schedule") {
            showingScheduleGeneration = true
          }
          .disabled(selectedOperation == nil)
        }

        ToolbarItem(placement: .secondaryAction) {
          if let operation = selectedOperation {
            Menu {
              ShareLink(
                item: ImpactReportGenerator.generate(for: operation),
                preview: SharePreview(
                  "\(operation.name) Impact Report",
                  image: Image(systemName: "leaf.fill")
                )
              ) {
                Label("Text Report", systemImage: "doc.text")
              }
              ShareLink(
                item: ImpactReportGenerator.generateCSV(for: operation),
                preview: SharePreview(
                  "\(operation.name) Donation Data",
                  image: Image(systemName: "tablecells")
                )
              ) {
                Label("CSV Data", systemImage: "tablecells")
              }
            } label: {
              Label("Export", systemImage: "square.and.arrow.up")
            }
          }
        }
      }
      .sheet(isPresented: $showingScheduleGeneration) {
        if let operation = selectedOperation {
          ScheduleGenerationView(operation: operation, date: selectedDate, viewModel: viewModel)
        }
      }
      .sheet(isPresented: $showingAddFoodBank) {
        FoodBankOnboardingView()
      }
      .sheet(isPresented: $showingAddStore) {
        FoodProviderRegistrationView()
      }
      .sheet(isPresented: $showingEmailProcessing) {
        EmailProcessingView()
      }
      .onAppear {
        viewModel.loadOperations(modelContext: modelContext)
      }
    }
  }

// MARK: - Greeting Card

struct GreetingCard: View {
  let operation: RegionalOperation
  let date: Date
  let operatorName: String

  private var greeting: String {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 5..<12: return "Good morning"
    case 12..<17: return "Good afternoon"
    default: return "Good evening"
    }
  }

  private var greetingIcon: String {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 5..<12: return "sun.rise.fill"
    case 12..<17: return "sun.max.fill"
    default: return "moon.stars.fill"
    }
  }

  private var todaysRoutes: [PickupRoute] {
    let calendar = Calendar.current
    return operation.pickupRoutes.filter { calendar.isDate($0.date, inSameDayAs: date) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text("\(greeting), \(operatorName.components(separatedBy: " ").first ?? operatorName)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(AppTheme.Colors.textPrimary)
          Text(date.formatted(date: .complete, time: .omitted))
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
        }
        Spacer()
        Image(systemName: greetingIcon)
          .font(.largeTitle)
          .foregroundColor(.orange)
      }

      Divider()

      HStack(spacing: 16) {
        Label(
          "\(todaysRoutes.count) route\(todaysRoutes.count == 1 ? "" : "s") today",
          systemImage: "truck.box.fill"
        )
        .font(.subheadline)
        .foregroundColor(todaysRoutes.isEmpty ? AppTheme.Colors.textSecondary : .blue)

        Spacer()

        let activeCount = todaysRoutes.filter { $0.status == .active }.count
        if activeCount > 0 {
          Label("\(activeCount) active", systemImage: "circle.fill")
            .font(.subheadline)
            .foregroundColor(.green)
        }
      }
    }
    .padding()
    .background(Color.blue.opacity(0.05))
    .cornerRadius(12)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.1)))
  }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
  let operation: RegionalOperation
  let onGenerateSchedule: () -> Void
  let onAddFoodBank: () -> Void
  let onAddStore: () -> Void
  let onProcessEmails: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "bolt.fill")
          .foregroundColor(.yellow)
        Text("Quick Actions")
          .font(.headline)
        Spacer()
      }

      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        QuickActionButton(title: "Generate Schedule", icon: "calendar.badge.plus", color: .blue, action: onGenerateSchedule)
        QuickActionButton(title: "Process Emails", icon: "envelope.badge", color: .purple, action: onProcessEmails)
        QuickActionButton(title: "Add Food Bank", icon: "house.badge.plus", color: .green, action: onAddFoodBank)
        QuickActionButton(title: "Add Store", icon: "storefront", color: .orange, action: onAddStore)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

private struct QuickActionButton: View {
  let title: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundColor(color)
        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .multilineTextAlignment(.center)
          .foregroundColor(AppTheme.Colors.textPrimary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(color.opacity(0.08))
      .cornerRadius(10)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Urgent Alerts Card

struct UrgentAlertsCard: View {
  let operation: RegionalOperation

  private var expiringDonations: [Donation] {
    let soon = Date().addingTimeInterval(48 * 3600)
    return operation.foodProviders.flatMap { $0.donations }.filter {
      guard let exp = $0.expirationDate else { return false }
      return exp <= soon && exp >= Date() && $0.status != .delivered && $0.status != .cancelled
    }
  }

  private var overduePickups: [Pickup] {
    operation.pickupRoutes.flatMap { $0.pickups }.filter { $0.isOverdue }
  }

  private var nearCapacityBanks: [FoodBank] {
    operation.foodBanks.filter { $0.utilizationPercentage >= 90 }
  }

  private var totalAlerts: Int { expiringDonations.count + overduePickups.count + nearCapacityBanks.count }

  var body: some View {
    if totalAlerts > 0 {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
          Text("Urgent Alerts")
            .font(.headline)
          Spacer()
          Text("\(totalAlerts)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.red)
            .clipShape(Capsule())
        }

        ForEach(expiringDonations.prefix(3), id: \.id) { donation in
          UrgentAlertRow(
            icon: "clock.badge.exclamationmark.fill",
            color: .orange,
            message: "\(donation.foodType.rawValue.capitalized) donation expiring \(donation.expirationDate!.formatted(date: .abbreviated, time: .omitted))"
          )
        }
        if expiringDonations.count > 3 {
          Text("+ \(expiringDonations.count - 3) more expiring soon")
            .font(.caption).foregroundColor(.orange)
        }

        ForEach(overduePickups.prefix(2), id: \.id) { pickup in
          UrgentAlertRow(
            icon: "truck.badge.exclamationmark.fill",
            color: .red,
            message: "Overdue pickup: \(pickup.foodProvider?.name ?? pickup.restaurant?.name ?? "Unknown")"
          )
        }
        if overduePickups.count > 2 {
          Text("+ \(overduePickups.count - 2) more overdue pickups")
            .font(.caption).foregroundColor(.red)
        }

        ForEach(nearCapacityBanks.prefix(2), id: \.id) { bank in
          UrgentAlertRow(
            icon: "house.badge.exclamationmark.fill",
            color: .purple,
            message: "\(bank.name) at \(bank.utilizationPercentage, specifier: "%.0f")% capacity"
          )
        }
      }
      .padding()
      .background(Color.red.opacity(0.05))
      .cornerRadius(12)
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.15)))
    }
  }
}

private struct UrgentAlertRow: View {
  let icon: String
  let color: Color
  let message: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .foregroundColor(color)
        .font(.subheadline)
      Text(message)
        .font(.subheadline)
        .foregroundColor(AppTheme.Colors.textPrimary)
        .lineLimit(2)
    }
  }
}

// MARK: - Operation Overview Card

struct OperationOverviewCard: View {
  let operation: RegionalOperation

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "building.2")
          .foregroundColor(.blue)
        Text("Operation Overview")
          .font(.headline)
        Spacer()
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Food Banks")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(operation.foodBanks.count)/\(operation.maxFoodBanks)")
            .font(.title2)
            .fontWeight(.semibold)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Food Providers")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(operation.foodProviders.count)")
            .font(.title2)
            .fontWeight(.semibold)
        }
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Service Radius")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(operation.radiusMiles, specifier: "%.0f") miles")
            .font(.title2)
            .fontWeight(.semibold)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Operating Hours")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text(operation.operationHours)
            .font(.title2)
            .fontWeight(.semibold)
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct TodaysScheduleCard: View {
  let operation: RegionalOperation
  let date: Date

  var todaysRoutes: [PickupRoute] {
    let calendar = Calendar.current
    return operation.pickupRoutes.filter { route in
      calendar.isDate(route.date, inSameDayAs: date)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "calendar")
          .foregroundColor(.green)
        Text("Today's Schedule")
          .font(.headline)
        Spacer()
        Text("\(todaysRoutes.count) routes")
          .font(.caption)
          .foregroundColor(AppTheme.Colors.textSecondary)
      }

      if todaysRoutes.isEmpty {
        Text("No routes scheduled for today")
          .font(.body)
          .foregroundColor(AppTheme.Colors.textSecondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding()
      } else {
        ForEach(todaysRoutes, id: \.id) { route in
          RouteCard(route: route)
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct RouteCard: View {
  let route: PickupRoute

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(route.startTime, style: .time)
          .font(.headline)
        Spacer()
        StatusBadge(status: route.status.rawValue)
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Pickups")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(route.pickups.count)")
            .font(.body)
            .fontWeight(.medium)
        }

        Spacer()

        VStack(alignment: .center) {
          Text("Deliveries")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(route.deliveries.count)")
            .font(.body)
            .fontWeight(.medium)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Distance")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(route.totalDistance, specifier: "%.1f") mi")
            .font(.body)
            .fontWeight(.medium)
        }
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Total Quantity")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(route.totalPickupQuantity, specifier: "%.0f") lbs")
            .font(.body)
            .fontWeight(.medium)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Duration")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(route.estimatedDuration / 3600, specifier: "%.1f") hrs")
            .font(.body)
            .fontWeight(.medium)
        }
      }
    }
    .padding()
    .background(Color.white)
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    )
  }
}

struct WeeklyTrendCard: View {
  let operation: RegionalOperation

  struct DailyLbs: Identifiable {
    let id = UUID()
    let label: String
    let lbs: Double
  }

  var chartData: [DailyLbs] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let allDonations = operation.foodProviders.flatMap { $0.donations }
    return stride(from: 6, through: 0, by: -1).map { daysAgo in
      let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
      let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
      let lbs = allDonations
        .filter { $0.createdAt >= day && $0.createdAt < nextDay }
        .reduce(0.0) { $0 + $1.quantity }
      let label = daysAgo == 0 ? "Today" : day.formatted(.dateTime.weekday(.abbreviated))
      return DailyLbs(label: label, lbs: lbs)
    }
  }

  var weekTotal: Double { chartData.reduce(0) { $0 + $1.lbs } }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "chart.bar.fill")
          .foregroundColor(.blue)
        Text("7-Day Trend")
          .font(.headline)
        Spacer()
        Text("\(weekTotal, specifier: "%.0f") lbs this week")
          .font(.caption)
          .foregroundColor(AppTheme.Colors.textSecondary)
      }

      Chart(chartData) { day in
        BarMark(
          x: .value("Day", day.label),
          y: .value("lbs", day.lbs)
        )
        .foregroundStyle(Color.blue.gradient)
        .cornerRadius(4)
      }
      .frame(height: 120)
      .chartYAxis {
        AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct StatisticsCard: View {
  let operation: RegionalOperation

  var totalDonations: Int {
    operation.foodProviders.flatMap { $0.donations }.count
  }

  var totalQuantity: Double {
    operation.foodProviders.flatMap { $0.donations }.reduce(0) { $0 + $1.quantity }
  }

  var completedDeliveries: Int {
    operation.foodBanks.flatMap { $0.deliveries }.filter { $0.status == .completed }.count
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "chart.bar")
          .foregroundColor(.orange)
        Text("Statistics")
          .font(.headline)
        Spacer()
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Total Donations")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(totalDonations)")
            .font(.title2)
            .fontWeight(.semibold)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Total Quantity")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(totalQuantity, specifier: "%.0f") lbs")
            .font(.title2)
            .fontWeight(.semibold)
        }
      }

      HStack {
        VStack(alignment: .leading) {
          Text("Completed Deliveries")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(completedDeliveries)")
            .font(.title2)
            .fontWeight(.semibold)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Food Waste Saved")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(totalQuantity, specifier: "%.0f") lbs")
            .font(.title2)
            .fontWeight(.semibold)
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct FoodBankStatusCard: View {
  let operation: RegionalOperation

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "house")
          .foregroundColor(.purple)
        Text("Food Bank Status")
          .font(.headline)
        Spacer()
      }

      ForEach(operation.foodBanks, id: \.id) { foodBank in
        HStack {
          VStack(alignment: .leading) {
            Text(foodBank.name)
              .font(.body)
              .fontWeight(.medium)
            Text("\(foodBank.availableCapacity) lbs available")
              .font(.caption)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }

          Spacer()

          VStack(alignment: .trailing) {
            Text("\(foodBank.utilizationPercentage, specifier: "%.0f")%")
              .font(.body)
              .fontWeight(.medium)
              .foregroundColor(foodBank.utilizationPercentage > 80 ? .red : .green)
            Text("utilization")
              .font(.caption)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct SustainabilityImpactCard: View {
  let operation: RegionalOperation

  var totalQuantity: Double {
    operation.foodProviders.flatMap { $0.donations }.reduce(0) { $0 + $1.quantity }
  }

  var totalCarbonOffset: Double {
    operation.foodProviders.flatMap { $0.donations }.reduce(0) { $0 + $1.carbonOffset }
  }

  var mealsProvided: Int {
    Int(totalQuantity / 1.2) // Assume 1.2 lbs per meal
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "leaf.fill")
          .foregroundColor(.green)
        Text("Sustainability Impact")
          .font(.headline)
        Spacer()
      }

      HStack {
        VStack(alignment: .leading) {
          Text("CO2 Diverted")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(totalCarbonOffset, specifier: "%.0f") kg")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.green)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text("Meals Provided")
            .font(.caption)
            .foregroundColor(AppTheme.Colors.textSecondary)
          Text("\(mealsProvided)")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
      }
      
      Text("Your regional recovery efforts have prevented significant methane emissions and supported local communities.")
        .font(.caption)
        .foregroundColor(AppTheme.Colors.textSecondary)
        .italic()
    }
    .padding()
    .background(Color.green.opacity(0.05))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.green.opacity(0.1), lineWidth: 1)
    )
  }
}

struct RecentActivityCard: View {
  let operation: RegionalOperation

  var recentActivity: [Any] {
    var activities: [Any] = []
    activities.append(contentsOf: operation.pickupRoutes.suffix(3))
    let allDonations = operation.foodProviders.flatMap { store in
      store.donations
    }
    activities.append(contentsOf: allDonations.suffix(3))
    return activities.suffix(5)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "clock")
          .foregroundColor(.blue)
        Text("Recent Activity")
          .font(.headline)
        Spacer()
      }

      if recentActivity.isEmpty {
        Text("No recent activity")
          .font(.body)
          .foregroundColor(AppTheme.Colors.textSecondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding()
      } else {
        ForEach(0..<recentActivity.count, id: \.self) { index in
          if let route = recentActivity[index] as? PickupRoute {
            HStack {
              Image(systemName: "truck")
                .foregroundColor(.blue)
              Text("Route created for \(route.date, style: .date)")
                .font(.body)
              Spacer()
            }
          } else if let donation = recentActivity[index] as? Donation {
            HStack {
              Image(systemName: "gift")
                .foregroundColor(.green)
              Text("\(donation.foodType.rawValue.capitalized) donation received")
                .font(.body)
              Spacer()
            }
          }
        }
      }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
  }
}

struct StatusBadge: View {
  let status: String

  var color: Color {
    switch status {
    case "planned": return .blue
    case "active": return .green
    case "completed": return .gray
    case "cancelled": return .red
    default: return .gray
    }
  }

  var body: some View {
    Text(status.capitalized)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.2))
      .foregroundColor(color)
      .cornerRadius(8)
  }
}

struct ScheduleGenerationView: View {
  let operation: RegionalOperation
  let date: Date
  let viewModel: RegionalOperationViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var errorMessage: String?
  @State private var generatedRoutes: [PickupRoute] = []
  @State private var showingPreview = false

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Generate Schedule for \(date, style: .date)")
          .font(.title2)
          .fontWeight(.semibold)

        Text("This will create optimized pickup and delivery routes for the selected date.")
          .font(.body)
          .foregroundColor(AppTheme.Colors.textSecondary)
          .multilineTextAlignment(.center)

        if showingPreview {
          GeneratedRoutesPreview(routes: generatedRoutes, onDone: { dismiss() })
        } else if viewModel.isLoading {
          ProgressView("Generating schedule...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          Button("Generate Schedule") {
            Task {
              viewModel.errorMessage = nil
              await viewModel.generateDailySchedule(for: operation, on: date)
              if let msg = viewModel.errorMessage {
                errorMessage = msg
              } else {
                let calendar = Calendar.current
                generatedRoutes = operation.pickupRoutes.filter {
                  calendar.isDate($0.date, inSameDayAs: date)
                }
                showingPreview = true
              }
            }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
        }

        Spacer()
      }
      .padding()
      .navigationTitle("Schedule Generation")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Schedule Generation Failed", isPresented: .init(
        get: { errorMessage != nil },
        set: { if !$0 { errorMessage = nil } }
      )) {
        Button("OK") { errorMessage = nil }
      } message: {
        Text(errorMessage ?? "")
      }
    }
  }
}

private struct GeneratedRoutesPreview: View {
  let routes: [PickupRoute]
  let onDone: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
        Text("\(routes.count) route\(routes.count == 1 ? "" : "s") generated")
          .font(.headline)
      }

      if routes.isEmpty {
        Text("No pickups or deliveries could be scheduled. Add food providers and food banks first.")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding()
      } else {
        ForEach(routes, id: \.id) { route in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("\(route.startTime.formatted(date: .omitted, time: .shortened)) – \(route.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .fontWeight(.medium)
              Spacer()
              RouteStatusBadge(status: route.status)
            }
            Text("\(route.pickups.count) pickup\(route.pickups.count == 1 ? "" : "s") · \(route.deliveries.count) deliver\(route.deliveries.count == 1 ? "y" : "ies")")
              .font(.caption)
              .foregroundColor(.secondary)
            if route.totalDistance > 0 {
              Text(String(format: "%.1f mi · %.0f min", route.totalDistance, route.estimatedDuration / 60))
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(12)
          .background(Color.green.opacity(0.05))
          .cornerRadius(10)
          .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.15)))
        }
      }

      Button("Done", action: onDone)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
    }
  }
}

// MARK: - Impact Report Generator

enum ImpactReportGenerator {
  static func generate(for operation: RegionalOperation) -> String {
    let donations = operation.foodProviders.flatMap { $0.donations }
    let totalLbs = donations.reduce(0.0) { $0 + $1.quantity }
    let totalCO2 = donations.reduce(0.0) { $0 + $1.carbonOffset }
    let totalMeals = Int(totalLbs / 1.2)
    let completedDeliveries = operation.foodBanks.flatMap { $0.deliveries }
      .filter { $0.status == .completed }.count
    let completedRoutes = operation.pickupRoutes.filter { $0.status == .completed }.count

    let divider = String(repeating: "═", count: 40)
    let thinDivider = String(repeating: "─", count: 40)

    let foodBankSection = operation.foodBanks.map {
      String(format: "  • %-25s %3.0f%% utilized  (%d lbs available)",
             ($0.name as NSString).utf8String ?? "",
             $0.utilizationPercentage,
             $0.availableCapacity)
    }.joined(separator: "\n")

    let donationBreakdown = FoodType.allCases.compactMap { type -> String? in
      let subset = donations.filter { $0.foodType == type }
      guard !subset.isEmpty else { return nil }
      let lbs = subset.reduce(0.0) { $0 + $1.quantity }
      return String(format: "  • %-16s %3d donations  %6.0f lbs",
                    (type.rawValue.capitalized as NSString).utf8String ?? "",
                    subset.count,
                    lbs)
    }.joined(separator: "\n")

    return """
    \(divider)
    FOOD RECOVERY IMPACT REPORT
    \(operation.name)
    Generated: \(Date().formatted(date: .long, time: .shortened))
    \(divider)

    SUMMARY
    \(thinDivider)
    Total Food Rescued:      \(String(format: "%.0f lbs", totalLbs))
    Estimated Meals:         \(totalMeals)
    CO\u{2082} Emissions Diverted:  \(String(format: "%.0f kg", totalCO2))
    Completed Deliveries:    \(completedDeliveries)
    Completed Routes:        \(completedRoutes)
    Service Radius:          \(String(format: "%.0f miles", operation.radiusMiles))
    Operating Hours:         \(operation.operationHours)

    FOOD BANK STATUS
    \(thinDivider)
    \(foodBankSection.isEmpty ? "  No food banks registered." : foodBankSection)

    DONATION BREAKDOWN BY TYPE
    \(thinDivider)
    \(donationBreakdown.isEmpty ? "  No donations recorded." : donationBreakdown)

    \(divider)
    Generated by Food Recovery App
    Committed to Zero Food Waste
    \(divider)
    """
  }

  static func generateCSV(for operation: RegionalOperation) -> String {
    let header = "Date,Provider,Food Type,Quantity (lbs),CO2 Offset (kg),Status,Description"
    let rows = operation.foodProviders.flatMap { provider in
      provider.donations.map { d in
        [
          d.createdAt.formatted(date: .numeric, time: .omitted),
          "\"\(provider.name)\"",
          d.foodType.rawValue,
          String(format: "%.1f", d.quantity),
          String(format: "%.1f", d.carbonOffset),
          d.status.rawValue,
          "\"\(d.foodDescription.replacingOccurrences(of: "\"", with: "\"\""))\""
        ].joined(separator: ",")
      }
    }.sorted()
    return ([header] + rows).joined(separator: "\n")
  }
}

#Preview {
  RegionalDashboardView()
}
