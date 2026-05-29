//
//  ContentView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftData
import SwiftUI

private let demoDataLoadedKey = "demoDataLoaded"

// MARK: - Analytics screen names aligned with NavigationItem

extension NavigationItem {
    var analyticsName: String { rawValue }
}

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
  @EnvironmentObject var authService: FirebaseAuthService
  @EnvironmentObject var firestoreService: FirestoreService
  @EnvironmentObject var realtimeRouteService: RealtimeRouteService

  @State private var selectedItem: NavigationItem = .dashboard
  @AppStorage("onboardingCompleted") private var onboardingCompleted = false
  @State private var showingOnboarding = false
  @State private var showingSignOutConfirm = false

  var body: some View {
    NavigationSplitView {
      List(NavigationItem.allCases, id: \.self) { item in
        Button(action: {
          selectedItem = item
          FirebaseAnalyticsService.shared.logScreen(item.analyticsName)
        }) {
          Label(item.rawValue, systemImage: item.icon)
            .foregroundColor(selectedItem == item ? .accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
      }
      .navigationTitle("Food Recovery")
      .listStyle(SidebarListStyle())
      .toolbar {
        ToolbarItem(placement: .automatic) {
          Button(action: { showingSignOutConfirm = true }) {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
          }
          .help("Sign out of your account")
        }
      }
      .safeAreaInset(edge: .bottom) {
        userBadge
          .padding(.horizontal, 12)
          .padding(.bottom, 12)
      }
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
        // Sync demo data to Firestore on first launch
        Task { await syncDemoDataToFirestore() }
      }
      if !onboardingCompleted {
        showingOnboarding = true
      }
      FirebaseAnalyticsService.shared.logScreen(selectedItem.analyticsName)
    }
    .sheet(isPresented: $showingOnboarding) {
      OnboardingView(isPresented: $showingOnboarding)
    }
    .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirm, titleVisibility: .visible) {
      Button("Sign Out", role: .destructive) {
        FirebaseAnalyticsService.shared.log(.userSignedOut)
        authService.signOut()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Are you sure you want to sign out?")
    }
  }

  // MARK: - User badge in sidebar footer

  private var userBadge: some View {
    HStack(spacing: 8) {
      Image(systemName: authService.isAnonymous ? "person.crop.circle.badge.questionmark" : "person.crop.circle.fill")
        .foregroundColor(.green)
      VStack(alignment: .leading, spacing: 2) {
        Text(authService.displayName)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.primary)
          .lineLimit(1)
        Text(authService.isAnonymous ? "Guest" : "Operator")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
    .padding(8)
    .background(Color.secondary.opacity(0.08))
    .cornerRadius(8)
  }

  // MARK: - Firestore sync

  private func syncDemoDataToFirestore() async {
    let descriptor = FetchDescriptor<RegionalOperation>()
    guard let ops = try? modelContext.fetch(descriptor) else { return }
    for op in ops {
      await firestoreService.syncOperation(op)
    }
  }
}

#Preview {
  ContentView()
    .modelContainer(for: RegionalOperation.self, inMemory: true)
}
