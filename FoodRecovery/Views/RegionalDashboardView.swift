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
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var selectedOperation: RegionalOperation?
  @State private var selectedDate = Date()
  @State private var showingScheduleGeneration = false


  var body: some View {
    VStack {
        if let operation = selectedOperation {
          ScrollView {
            VStack(spacing: 20) {
              // Operation Overview
              OperationOverviewCard(operation: operation)

              // Today's Schedule
              TodaysScheduleCard(operation: operation, date: selectedDate)

              // Statistics
              StatisticsCard(operation: operation)

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
            ShareLink(
              item: ImpactReportGenerator.generate(for: operation),
              preview: SharePreview(
                "\(operation.name) Impact Report",
                image: Image(systemName: "leaf.fill")
              )
            ) {
              Label("Export Report", systemImage: "square.and.arrow.up")
            }
          }
        }
      }
      .sheet(isPresented: $showingScheduleGeneration) {
        if let operation = selectedOperation {
          ScheduleGenerationView(operation: operation, date: selectedDate, viewModel: viewModel)
        }
      }
      .onAppear {
        viewModel.loadOperations(modelContext: modelContext)
      }
    }
  }

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

        if viewModel.isLoading {
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
                dismiss()
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
}

#Preview {
  RegionalDashboardView()
}
