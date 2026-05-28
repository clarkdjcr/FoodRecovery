//
//  FoodBankOnboardingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct FoodBankOnboardingView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var selectedOperation: RegionalOperation?
  @State private var name = ""
  @State private var address = ""
  @State private var location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
  @State private var capacity = 1000.0
  @State private var dailyUsage = 500.0
  @State private var contactName = ""
  @State private var contactEmail = ""
  @State private var contactPhone = ""
  @State private var operatingHours = "9:00 AM - 5:00 PM"
  @State private var specialRequirements = ""
  @State private var showingMap = false
  @State private var showingSuccess = false
  @State private var phoneValidationError: String?


  var body: some View {
    // NavigationView {
      ScrollView {
        LazyVStack(spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text("Food Bank Onboarding")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Register a new food bank to join your regional operation")
              .font(.subheadline)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          
          // Operation Selection
          ModernSectionCard(
            "Regional Operation",
            subtitle: "Select the operation this food bank will join",
            icon: "building.2.fill"
          ) {
            ModernPicker(
              "Operation",
              selection: $selectedOperation,
              icon: "building.2"
            ) {
              Text("Select an operation").tag(nil as RegionalOperation?)
              ForEach(viewModel.operations, id: \.id) { operation in
                Text(operation.name).tag(operation as RegionalOperation?)
              }
            }
          }
          .padding(.horizontal)
          
          // Food Bank Details
          ModernSectionCard(
            "Food Bank Details",
            subtitle: "Basic information about the food bank",
            icon: "house.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Food Bank Name",
                placeholder: "Enter food bank name",
                text: $name,
                icon: "house"
              )
              
              ModernTextField(
                title: "Address",
                placeholder: "Enter full address",
                text: $address,
                icon: "location"
              )
              
              LocationDisplayCard(
                latitude: location.latitude,
                longitude: location.longitude,
                onSelectLocation: { showingMap = true }
              )
            }
          }
          .padding(.horizontal)
          
          // Capacity & Usage
          ModernSectionCard(
            "Capacity & Usage",
            subtitle: "Daily capacity and current usage metrics",
            icon: "chart.bar.fill"
          ) {
            VStack(spacing: 20) {
              ModernSlider(
                "Daily Capacity",
                value: $capacity,
                in: 100...5000,
                step: 50,
                icon: "scalemass",
                unit: "lbs"
              )
              
              ModernSlider(
                "Current Usage",
                value: $dailyUsage,
                in: 0...capacity,
                step: 25,
                icon: "chart.line.uptrend.xyaxis",
                unit: "lbs"
              )
              
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Available Capacity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                  Text("\(Int(capacity - dailyUsage)) lbs")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(capacity - dailyUsage > 0 ? .green : .red)
                }
                
                Spacer()
                
                CircularProgressView(
                  progress: dailyUsage / capacity,
                  size: 60
                )
              }
              .padding(.top, 8)
            }
          }
          .padding(.horizontal)
          
          // Contact Information
          ModernSectionCard(
            "Contact Information",
            subtitle: "Primary contact details for coordination",
            icon: "person.crop.circle.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Contact Name",
                placeholder: "Enter contact person's name",
                text: $contactName,
                icon: "person"
              )
              
              ModernTextField(
                title: "Email Address",
                placeholder: "contact@foodbank.org",
                text: $contactEmail,
                icon: "envelope",
              )
              
              VStack(alignment: .leading, spacing: 4) {
                ModernTextField(
                  title: "Phone Number",
                  placeholder: "(555) 123-4567",
                  text: $contactPhone,
                  icon: "phone"
                )
                .onChange(of: contactPhone) { oldValue, newValue in
                  validatePhoneNumber()
                }
                
                if let error = phoneValidationError {
                  Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                }
              }
            }
          }
          .padding(.horizontal)
          
          // Operating Details
          ModernSectionCard(
            "Operating Details",
            subtitle: "Hours and special requirements",
            icon: "clock.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Operating Hours",
                placeholder: "9:00 AM - 5:00 PM",
                text: $operatingHours,
                icon: "clock"
              )
              
              ModernTextField(
                title: "Special Requirements",
                placeholder: "Any special handling, storage, or delivery requirements...",
                text: $specialRequirements,
                icon: "exclamationmark.circle",
                axis: .vertical,
                lineLimit: 3...6
              )
            }
          }
          .padding(.horizontal)
          
          // Submit Button
          ModernButton(
            title: "Add Food Bank",
            action: addFoodBank,
            style: .primary,
            icon: "plus.circle.fill",
            isEnabled: isFormValid
          )
          .padding(.horizontal)
          .padding(.bottom, 20)
        }
      }
      .background(Color(red: 0.95, green: 0.95, blue: 0.97))
      .sheet(isPresented: $showingMap) {
        MapSelectionView(selectedCoordinate: $location)
      }
      .alert("Food Bank Added Successfully!", isPresented: $showingSuccess) {
        Button("OK") {
          resetForm()
        }
      } message: {
        Text("\(name) has been successfully added to \(selectedOperation?.name ?? "the operation")!")
      }
      .onAppear {
        viewModel.loadOperations(modelContext: modelContext)
      }
    }
    
    // MARK: - Private Functions
    
    private var isFormValid: Bool {
        selectedOperation != nil &&
        !name.isEmpty &&
        !address.isEmpty &&
        !contactName.isEmpty &&
        !contactEmail.isEmpty &&
        !contactPhone.isEmpty &&
        phoneValidationError == nil &&
        PhoneValidationService.isValidPhoneNumber(contactPhone)
    }
    
    private func addFoodBank() {
        guard let operation = selectedOperation else { return }

        viewModel.addFoodBank(
            modelContext: modelContext,
            to: operation,
            name: name,
            address: address,
            location: location,
            capacity: Int(capacity),
            dailyUsage: Int(dailyUsage),
            contactName: contactName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            operatingHours: operatingHours,
            specialRequirements: specialRequirements
        )
        showingSuccess = true
    }
    
    private func validatePhoneNumber() {
        phoneValidationError = PhoneValidationService.getValidationError(for: contactPhone)
        
        // Auto-format phone number if valid
        if phoneValidationError == nil && !contactPhone.isEmpty {
            let formatted = PhoneValidationService.formatPhoneNumber(contactPhone)
            if formatted != contactPhone {
                contactPhone = formatted
            }
        }
    }
    
    private func resetForm() {
        name = ""
        address = ""
        location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        capacity = 1000.0
        dailyUsage = 500.0
        contactName = ""
        contactEmail = ""
        contactPhone = ""
        operatingHours = "9:00 AM - 5:00 PM"
        specialRequirements = ""
        phoneValidationError = nil
    }
}

#Preview {
  FoodBankOnboardingView()
}
