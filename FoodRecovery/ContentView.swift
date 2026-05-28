//
//  ContentView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftData
import SwiftUI

private let demoDataLoadedKey = "demoDataLoaded"

enum NavigationItem: String, CaseIterable, Identifiable {
  case dashboard = "Dashboard"
  case setup = "Regional Setup"
  case foodBanks = "Food Banks"
  case stores = "Food Providers"
  case aiProcessing = "AI Processing"
  case restaurants = "Restaurants"
  case routes = "Routes"
  case settings = "Settings"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .dashboard: return "chart.bar.fill"
    case .setup: return "building.2.fill"
    case .foodBanks: return "house.fill"
    case .stores: return "cart.fill"
    case .aiProcessing: return "envelope.fill"
    case .restaurants: return "fork.knife.circle.fill"
    case .routes: return "map.fill"
    case .settings: return "gearshape.fill"
    }
  }
}

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var selectedItem: NavigationItem = .dashboard
  @AppStorage("onboardingCompleted") private var onboardingCompleted = false
  @State private var showingOnboarding = false

  var body: some View {
    NavigationSplitView {
      List(NavigationItem.allCases, id: \.self) { item in
        Button(action: {
          selectedItem = item
        }) {
          Label(item.rawValue, systemImage: item.icon)
            .foregroundColor(selectedItem == item ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
      }
      .navigationTitle("Food Recovery")
      .listStyle(SidebarListStyle())
    } detail: {
      switch selectedItem {
      case .dashboard:
        RegionalDashboardView()
      case .setup:
        RegionalSetupView()
      case .foodBanks:
        FoodBankOnboardingView()
      case .stores:
        FoodProviderRegistrationView()
      case .aiProcessing:
        EmailProcessingView()
      case .restaurants:
        RestaurantOnboardingView()
      case .routes:
        RouteListView()
      case .settings:
        SettingsView()
      }
    }
    .accentColor(.green)
    .onAppear {
      if !UserDefaults.standard.bool(forKey: demoDataLoadedKey) {
        DemoDataService.createDemoData(modelContext: modelContext)
        UserDefaults.standard.set(true, forKey: demoDataLoadedKey)
      }
      if !onboardingCompleted {
        showingOnboarding = true
      }
    }
    .sheet(isPresented: $showingOnboarding) {
      OnboardingView(isPresented: $showingOnboarding)
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: RegionalOperation.self, inMemory: true)
}
