//
//  RegionalSetupView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct RegionalSetupView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var name = ""
  @State private var regionCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)  // Default to San Francisco
  @State private var radiusMiles = 35.0
  @State private var maxFoodBanks = 5.0
  @State private var operationHours = "8:00 AM - 6:00 PM"
  @State private var contactEmail = ""
  @State private var contactPhone = ""
  @State private var showingMap = false
  @State private var showingSuccess = false


  var body: some View {
    // NavigationView {
      ScrollView {
        LazyVStack(spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 12) {
            Text("Regional Setup")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Create a new regional food recovery operation to coordinate donations and deliveries in your area")
              .font(.subheadline)
              .foregroundColor(AppTheme.Colors.textSecondary)
            
            // Progress indicator
            OnboardingProgressView(
              currentStep: 0,
              totalSteps: 3,
              stepTitles: ["Operation Details", "Configure Region", "Set Schedule"]
            )
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          
          // Operation Details
          ModernSectionCard(
            "Operation Details",
            subtitle: "Basic information about your regional operation",
            icon: "building.2.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Operation Name",
                placeholder: "e.g., Bay Area Food Recovery",
                text: $name,
                icon: "building.2"
              )
              
              ModernTextField(
                title: "Contact Email",
                placeholder: "coordinator@foodrecovery.org",
                text: $contactEmail,
                icon: "envelope",
              )
              
              ModernTextField(
                title: "Contact Phone",
                placeholder: "(555) 123-4567",
                text: $contactPhone,
                icon: "phone",
              )
            }
          }
          .padding(.horizontal)
          
          // Regional Configuration
          ModernSectionCard(
            "Regional Configuration",
            subtitle: "Define the geographic scope of your operation",
            icon: "map.fill"
          ) {
            VStack(spacing: 20) {
              LocationDisplayCard(
                latitude: regionCenter.latitude,
                longitude: regionCenter.longitude,
                onSelectLocation: { showingMap = true }
              )
              
              ModernSlider(
                "Service Radius",
                value: $radiusMiles,
                in: 10...50,
                step: 5,
                icon: "circle.dotted",
                unit: "miles",
                formatter: radiusFormatter
              )
              
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text("Coverage Area")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                  Spacer()
                  Text("~\(Int(3.14159 * radiusMiles * radiusMiles)) sq miles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                }
                
                Text("This radius determines which stores and food banks can participate in your operation.")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
              }
              .padding(.top, 8)
              
              ModernSlider(
                "Maximum Food Banks",
                value: $maxFoodBanks,
                in: 1...10,
                step: 1,
                icon: "house.fill",
                formatter: maxFoodBanksFormatter
              )
            }
          }
          .padding(.horizontal)
          
          // Operating Schedule
          ModernSectionCard(
            "Operating Schedule",
            subtitle: "When your operation will be active",
            icon: "clock.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Operating Hours",
                placeholder: "8:00 AM - 6:00 PM",
                text: $operationHours,
                icon: "clock"
              )
              
              HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                  .foregroundColor(.blue)
                  .font(.subheadline)
                
                Text("Pickups and deliveries will be scheduled within these hours.")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
                  .multilineTextAlignment(.leading)
              }
            }
          }
          .padding(.horizontal)
          
          // Submit Button
          ModernButton(
            title: "Create Operation",
            action: createOperation,
            style: .primary,
            icon: "plus.circle.fill",
            isEnabled: isFormValid
          )
          .padding(.horizontal)
          .padding(.bottom, 20)
        }
      }
      .background(AppTheme.Colors.background)
      .sheet(isPresented: $showingMap) {
        MapSelectionView(selectedCoordinate: $regionCenter)
      }
      .alert("Operation Created Successfully!", isPresented: $showingSuccess) {
        Button("OK") {
          resetForm()
        }
      } message: {
        Text("\(name) has been created and is ready to coordinate food recovery in your region!")
      }
    }
    
    // MARK: - Private Functions
    
    private var isFormValid: Bool {
        !name.isEmpty && !contactEmail.isEmpty && !contactPhone.isEmpty
    }
    
    private func radiusFormatter(_ value: Double) -> String {
        "\(Int(value))"
    }
    
    private func maxFoodBanksFormatter(_ value: Double) -> String {
        "\(Int(value))"
    }
    
    private func createOperation() {
        viewModel.createOperation(
            modelContext: modelContext,
            name: name,
            regionCenter: regionCenter,
            radiusMiles: radiusMiles,
            maxFoodBanks: Int(maxFoodBanks),
            operationHours: operationHours,
            contactEmail: contactEmail,
            contactPhone: contactPhone
        )
        showingSuccess = true
    }
    
    private func resetForm() {
        name = ""
        regionCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        radiusMiles = 35.0
        maxFoodBanks = 5.0
        operationHours = "8:00 AM - 6:00 PM"
        contactEmail = ""
        contactPhone = ""
    }
}

struct MapSelectionView: View {
  @Binding var selectedCoordinate: CLLocationCoordinate2D
  @Environment(\.dismiss) private var dismiss
  @State private var region: MKCoordinateRegion

  init(selectedCoordinate: Binding<CLLocationCoordinate2D>) {
    _selectedCoordinate = selectedCoordinate
    _region = State(initialValue: MKCoordinateRegion(
      center: selectedCoordinate.wrappedValue,
      span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
  }

  var body: some View {
    // NavigationView {
      ZStack {
        MapReader { proxy in
          Map(position: .constant(.region(region))) {
            Marker("Selected Location", coordinate: selectedCoordinate)
              .tint(.blue)
          }
          .mapStyle(.standard(elevation: .flat))
          .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
          }
          .onMapCameraChange { context in
            region = context.region
          }
          .onTapGesture { screenCoordinate in
            if let coordinate = proxy.convert(screenCoordinate, from: .local) {
              selectedCoordinate = coordinate
              region = MKCoordinateRegion(
                center: coordinate,
                span: region.span
              )
            }
          }
        }
        
        // Center crosshair to show selection point
        VStack {
          Spacer()
          HStack {
            Spacer()
            VStack(spacing: 0) {
              Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
              VStack {
                Rectangle()
                  .fill(.blue)
                  .frame(width: 2, height: 20)
                Text("Tap map or use center point")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
                  .padding(.top, 4)
              }
            }
            Spacer()
          }
          Spacer()
        }
        
        // Location info card
        VStack {
          Spacer()
          
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Image(systemName: "location.fill")
                .foregroundColor(.blue)
              Text("Selected Location")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
              Spacer()
            }
            
            HStack(spacing: 16) {
              VStack(alignment: .leading, spacing: 2) {
                Text("Latitude")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
                Text(String(format: "%.4f", selectedCoordinate.latitude))
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundColor(AppTheme.Colors.textPrimary)
              }

              VStack(alignment: .leading, spacing: 2) {
                Text("Longitude")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
                Text(String(format: "%.4f", selectedCoordinate.longitude))
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundColor(AppTheme.Colors.textPrimary)
              }
              
              Spacer()
            }
          }
          .padding(16)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(.regularMaterial)
              .shadow(radius: 8)
          )
          .padding()
        }
      }
      .navigationTitle("Select Location")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .foregroundColor(AppTheme.Colors.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Select") {
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }

struct MapAnnotation: Identifiable {
  let id = UUID()
  let coordinate: CLLocationCoordinate2D
}

#Preview {
  RegionalSetupView()
}
