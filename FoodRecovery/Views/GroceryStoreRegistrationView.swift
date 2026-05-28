//
//  GroceryStoreRegistrationView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct FoodProviderRegistrationView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var selectedOperation: RegionalOperation?
  @State private var name = ""
  @State private var address = ""
  @State private var location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
  @State private var contactName = ""
  @State private var contactEmail = ""
  @State private var contactPhone = ""
  @State private var donationEmail = ""
  @State private var operatingHours = "7:00 AM - 10:00 PM"
  @State private var preferredPickupTimes = "morning"
  @State private var showingMap = false
  @State private var showingSuccess = false
  @State private var phoneValidationError: String?


  var body: some View {
    // NavigationView {
      ScrollView {
        LazyVStack(spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Text("Food Provider Registration")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(AppTheme.Colors.textPrimary)
            Text("Register your food provider to participate in food waste recovery")
              .font(.subheadline)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          
          // Operation Selection
          ModernSectionCard(
            "Regional Operation",
            subtitle: "Select the operation your store will join",
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
          
          // Store Details
          ModernSectionCard(
            "Provider Details",
            subtitle: "Basic information about your food provider",
            icon: "storefront.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Provider Name",
                placeholder: "Enter provider name",
                text: $name,
                icon: "storefront"
              )
              
              ModernTextField(
                title: "Address",
                placeholder: "Enter full store address",
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
          
          // Contact Information
          ModernSectionCard(
            "Contact Information",
            subtitle: "Primary contact for store coordination",
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
                placeholder: "contact@store.com",
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
          
          // Donation Email Setup
          ModernSectionCard(
            "Donation Notifications",
            subtitle: "Email setup for donation alerts and confirmations",
            icon: "envelope.badge.fill"
          ) {
            VStack(alignment: .leading, spacing: 12) {
              ModernTextField(
                title: "Donation Email Address",
                placeholder: "donations@store.com",
                text: $donationEmail,
                icon: "envelope.open",
              )
              
              HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                  .foregroundColor(.blue)
                  .font(.subheadline)
                
                Text("This email will receive donation notifications and pickup confirmations.")
                  .font(.caption)
                  .foregroundColor(AppTheme.Colors.textSecondary)
                  .multilineTextAlignment(.leading)
              }
              .padding(.top, 4)
            }
          }
          .padding(.horizontal)
          
          // Operating Details
          ModernSectionCard(
            "Operating Schedule",
            subtitle: "Store hours and pickup preferences",
            icon: "clock.fill"
          ) {
            VStack(spacing: 16) {
              ModernTextField(
                title: "Operating Hours",
                placeholder: "7:00 AM - 10:00 PM",
                text: $operatingHours,
                icon: "clock"
              )
              
              ModernPicker(
                "Preferred Pickup Times",
                selection: $preferredPickupTimes,
                icon: "truck.pickup"
              ) {
                Text("Morning (8 AM - 12 PM)").tag("morning")
                Text("Afternoon (12 PM - 4 PM)").tag("afternoon")
                Text("Evening (4 PM - 8 PM)").tag("evening")
                Text("Flexible").tag("flexible")
              }
            }
          }
          .padding(.horizontal)
          
          // Submit Button
          ModernButton(
            title: "Register Provider",
            action: registerStore,
            style: .primary,
            icon: "checkmark.circle.fill",
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
      .alert("Provider Registered Successfully!", isPresented: $showingSuccess) {
        Button("OK") {
          resetForm()
        }
      } message: {
        Text("\(name) has been successfully registered with \(selectedOperation?.name ?? "the operation")!")
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
        !donationEmail.isEmpty &&
        phoneValidationError == nil &&
        PhoneValidationService.isValidPhoneNumber(contactPhone)
    }
    
    private func registerStore() {
    guard let operation = selectedOperation else { return }

    viewModel.addFoodProvider(
      modelContext: modelContext,
      to: operation,
      name: name,
      address: address,
      location: location,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      donationEmail: donationEmail,
      operatingHours: operatingHours,
      preferredPickupTimes: preferredPickupTimes
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
      contactName = ""
      contactEmail = ""
      contactPhone = ""
      donationEmail = ""
      operatingHours = "7:00 AM - 10:00 PM"
      preferredPickupTimes = "morning"
      phoneValidationError = nil
    }
  }

#Preview {
  FoodProviderRegistrationView()
}
