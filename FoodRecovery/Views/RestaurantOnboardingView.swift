//
//  RestaurantOnboardingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import SwiftData
import SwiftUI

struct RestaurantOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
    
    // Basic Info
    @State private var selectedOperation: RegionalOperation?
    @State private var name = ""
    @State private var businessName = ""
    @State private var ein = ""
    @State private var address = ""
    @State private var location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    
    // Business Details
    @State private var restaurantType: RestaurantType = .casualDining
    @State private var cuisineTypes: [String] = []
    @State private var avgDailyCovers = 100.0
    @State private var avgTicketValue = 25.0
    @State private var annualRevenueRange = "under_500k"
    
    // Operations
    @State private var serviceHours = "11:00 AM - 10:00 PM"
    @State private var kitchenHours = "11:00 AM - 9:30 PM"
    @State private var preferredPickupWindow = "9:30 PM - 10:30 PM"
    @State private var daysOfOperation: Set<String> = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    
    // Contact Info
    @State private var ownerName = ""
    @State private var managerName = ""
    @State private var contactEmail = ""
    @State private var contactPhone = ""
    @State private var accountingEmail = ""
    
    // Food Safety & Storage
    @State private var storageCapabilities: Set<StorageCapability> = [.refrigerated, .hotHolding]
    @State private var foodSafetyCertifications: Set<FoodSafetyCertification> = [.servsafe]
    @State private var healthGrade = "A"
    
    // Waste & Donations
    @State private var estimatedDailyWaste = 200.0
    @State private var estimatedDailyWastePounds = 30.0
    @State private var donationTypes: Set<String> = ["prepared_meals"]
    @State private var requiresPhotography = false
    @State private var specialInstructions = ""
    
    // UI State
    @State private var showingMap = false
    @State private var showingSuccess = false
    @State private var currentStep = 0
    @State private var showingTaxCalculator = false
    @State private var phoneValidationError: String?
    
    let steps = ["Basic Info", "Business Details", "Operations", "Food Safety", "Tax & Waste", "Contact Info"]
    let cuisineOptions = ["American", "Italian", "Mexican", "Chinese", "Japanese", "Indian", "Thai", "Mediterranean", "French", "Greek", "Korean", "Vietnamese", "Ethiopian", "Lebanese", "Vegetarian", "Vegan", "Gluten-Free", "BBQ", "Seafood", "Steakhouse"]
    let revenueRanges = ["under_250k": "Under $250K", "250k_500k": "$250K - $500K", "500k_1m": "$500K - $1M", "1m_2m": "$1M - $2M", "2m_5m": "$2M - $5M", "over_5m": "Over $5M"]
    let donationTypeOptions = ["prepared_meals": "Prepared Meals", "baked_goods": "Baked Goods", "ingredients": "Raw Ingredients", "beverages": "Beverages", "specialty_items": "Specialty Items"]
    let weekdays = ["monday": "Monday", "tuesday": "Tuesday", "wednesday": "Wednesday", "thursday": "Thursday", "friday": "Friday", "saturday": "Saturday", "sunday": "Sunday"]
    
    
    var body: some View {
        ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restaurant Partnership")
                            .font(AppTheme.Typography.largeTitle)
                        Text("Join our food recovery network and turn waste into tax benefits")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        OnboardingProgressView(
                            currentStep: currentStep,
                            totalSteps: steps.count,
                            stepTitles: steps
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Step Content
                    Group {
                        switch currentStep {
                        case 0: basicInfoStep
                        case 1: businessDetailsStep
                        case 2: operationsStep
                        case 3: foodSafetyStep
                        case 4: taxWasteStep
                        case 5: contactInfoStep
                        default: basicInfoStep
                        }
                    }
                    .padding(.horizontal)
                    
                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            ModernButton(
                                title: "Previous",
                                action: { currentStep -= 1 },
                                style: .secondary,
                                icon: "chevron.left"
                            )
                        }
                        
                        Spacer()
                        
                        if currentStep < steps.count - 1 {
                            ModernButton(
                                title: "Next",
                                action: { currentStep += 1 },
                                style: .primary,
                                icon: "chevron.right",
                                isEnabled: isCurrentStepValid
                            )
                        } else {
                            ModernButton(
                                title: "Complete Registration",
                                action: registerRestaurant,
                                style: .primary,
                                icon: "checkmark.circle.fill",
                                isEnabled: isFormValid
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(AppTheme.Colors.background)
            .sheet(isPresented: $showingMap) {
                MapSelectionView(selectedCoordinate: $location)
            }
            .sheet(isPresented: $showingTaxCalculator) {
                TaxBenefitCalculatorView(
                    dailyWaste: $estimatedDailyWaste,
                    operatingDays: daysOfOperation.count,
                    avgTicketValue: $avgTicketValue
                )
            }
            .alert("Restaurant Registered Successfully!", isPresented: $showingSuccess) {
                Button("OK") {
                    resetForm()
                    currentStep = 0
                }
            } message: {
                Text("Welcome to the food recovery network! \\(name) is now registered and can start donating excess food.")
            }
            .onAppear {
                viewModel.loadOperations(modelContext: modelContext)
            }
        }
    
    // MARK: - Step Views
    
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Regional Operation",
                subtitle: "Select your regional food recovery operation",
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
            
            ModernSectionCard(
                "Restaurant Information",
                subtitle: "Basic details about your establishment",
                icon: "storefront.fill"
            ) {
                VStack(spacing: 16) {
                    ModernTextField(
                        title: "Restaurant Name",
                        placeholder: "The name customers know you by",
                        text: $name,
                        icon: "storefront"
                    )
                    
                    ModernTextField(
                        title: "Legal Business Name",
                        placeholder: "Official business name for tax purposes",
                        text: $businessName,
                        icon: "building"
                    )
                    
                    ModernTextField(
                        title: "EIN (Tax ID)",
                        placeholder: "XX-XXXXXXX",
                        text: $ein,
                        icon: "number.square"
                    )
                    
                    ModernTextField(
                        title: "Address",
                        placeholder: "Full restaurant address",
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
        }
    }
    
    private var businessDetailsStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Restaurant Type & Cuisine",
                subtitle: "Help us understand your establishment",
                icon: "fork.knife.circle.fill"
            ) {
                VStack(spacing: 16) {
                    ModernPicker(
                        "Restaurant Type",
                        selection: $restaurantType,
                        icon: "building.2"
                    ) {
                        ForEach(RestaurantType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text("Cuisine Types")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(cuisineOptions, id: \.self) { cuisine in
                                CuisineToggleView(
                                    cuisine: cuisine,
                                    isSelected: cuisineTypes.contains(cuisine)
                                ) {
                                    if cuisineTypes.contains(cuisine) {
                                        cuisineTypes.removeAll { $0 == cuisine }
                                    } else {
                                        cuisineTypes.append(cuisine)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            ModernSectionCard(
                "Business Metrics",
                subtitle: "Help us calculate your tax benefits",
                icon: "chart.bar.fill"
            ) {
                VStack(spacing: 16) {
                    ModernSlider(
                        "Average Daily Covers",
                        value: $avgDailyCovers,
                        in: 10...1000,
                        step: 10,
                        icon: "person.2.fill",
                        unit: "customers"
                    )
                    
                    ModernSlider(
                        "Average Ticket Value",
                        value: $avgTicketValue,
                        in: 5...200,
                        step: 1,
                        icon: "dollarsign.circle",
                        unit: "$",
                        formatter: { String(format: "%.0f", $0) }
                    )
                    
                    ModernPicker(
                        "Annual Revenue Range",
                        selection: $annualRevenueRange,
                        icon: "chart.line.uptrend.xyaxis"
                    ) {
                        ForEach(revenueRanges.keys.sorted(), id: \.self) { key in
                            Text(revenueRanges[key] ?? "").tag(key)
                        }
                    }
                }
            }
        }
    }
    
    private var operationsStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Operating Schedule",
                subtitle: "When your restaurant operates and can donate",
                icon: "clock.fill"
            ) {
                VStack(spacing: 16) {
                    ModernTextField(
                        title: "Service Hours",
                        placeholder: "11:00 AM - 10:00 PM",
                        text: $serviceHours,
                        icon: "clock"
                    )
                    
                    ModernTextField(
                        title: "Kitchen Hours",
                        placeholder: "11:00 AM - 9:30 PM",
                        text: $kitchenHours,
                        icon: "flame"
                    )
                    
                    ModernTextField(
                        title: "Preferred Pickup Window",
                        placeholder: "9:30 PM - 10:30 PM",
                        text: $preferredPickupWindow,
                        icon: "truck.pickup"
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text("Days of Operation")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(weekdays.keys.sorted(), id: \.self) { day in
                                DayToggleView(
                                    day: weekdays[day] ?? "",
                                    isSelected: daysOfOperation.contains(day)
                                ) {
                                    if daysOfOperation.contains(day) {
                                        daysOfOperation.remove(day)
                                    } else {
                                        daysOfOperation.insert(day)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var foodSafetyStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Storage Capabilities",
                subtitle: "What types of food can you safely store and donate?",
                icon: "archivebox.fill"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(StorageCapability.allCases, id: \.self) { capability in
                        StorageCapabilityRow(
                            capability: capability,
                            isSelected: storageCapabilities.contains(capability)
                        ) {
                            if storageCapabilities.contains(capability) {
                                storageCapabilities.remove(capability)
                            } else {
                                storageCapabilities.insert(capability)
                            }
                        }
                    }
                }
            }
            
            ModernSectionCard(
                "Food Safety Certifications",
                subtitle: "Current certifications and health ratings",
                icon: "checkmark.shield.fill"
            ) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Certifications")
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(FoodSafetyCertification.allCases, id: \.self) { cert in
                            CertificationRow(
                                certification: cert,
                                isSelected: foodSafetyCertifications.contains(cert)
                            ) {
                                if foodSafetyCertifications.contains(cert) {
                                    foodSafetyCertifications.remove(cert)
                                } else {
                                    foodSafetyCertifications.insert(cert)
                                }
                            }
                        }
                    }
                    
                    ModernTextField(
                        title: "Health Department Grade",
                        placeholder: "A, B, C, etc.",
                        text: $healthGrade,
                        icon: "star.fill"
                    )
                }
            }
        }
    }
    
    private var taxWasteStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Food Waste Estimates",
                subtitle: "Help us calculate your potential tax benefits",
                icon: "chart.pie.fill"
            ) {
                VStack(spacing: 20) {
                    ModernSlider(
                        "Daily Food Waste Value",
                        value: $estimatedDailyWaste,
                        in: 50...2000,
                        step: 25,
                        icon: "dollarsign.circle",
                        unit: "$",
                        formatter: { String(format: "%.0f", $0) }
                    )
                    
                    ModernSlider(
                        "Daily Food Waste Weight",
                        value: $estimatedDailyWastePounds,
                        in: 5...500,
                        step: 5,
                        icon: "scalemass",
                        unit: "lbs",
                        formatter: { String(format: "%.0f", $0) }
                    )
                    
                    TaxBenefitPreviewCard(
                        dailyWaste: estimatedDailyWaste,
                        operatingDays: daysOfOperation.count,
                        onShowCalculator: { showingTaxCalculator = true }
                    )
                }
            }
            
            ModernSectionCard(
                "Donation Preferences",
                subtitle: "What types of food will you donate?",
                icon: "gift.fill"
            ) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Donation Types")
                            .font(AppTheme.Typography.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(donationTypeOptions.keys.sorted(), id: \.self) { key in
                            DonationTypeRow(
                                type: donationTypeOptions[key] ?? "",
                                isSelected: donationTypes.contains(key)
                            ) {
                                if donationTypes.contains(key) {
                                    donationTypes.remove(key)
                                } else {
                                    donationTypes.insert(key)
                                }
                            }
                        }
                    }
                    
                    HStack {
                        Toggle("Require Photo Documentation", isOn: $requiresPhotography)
                            .font(AppTheme.Typography.subheadline)
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    ModernTextField(
                        title: "Special Instructions",
                        placeholder: "Any special handling or pickup requirements...",
                        text: $specialInstructions,
                        icon: "text.bubble",
                        axis: .vertical,
                        lineLimit: 2...4
                    )
                }
            }
        }
    }
    
    private var contactInfoStep: some View {
        VStack(spacing: 20) {
            ModernSectionCard(
                "Restaurant Contacts",
                subtitle: "Key personnel for coordination",
                icon: "person.2.fill"
            ) {
                VStack(spacing: 16) {
                    ModernTextField(
                        title: "Owner Name",
                        placeholder: "Restaurant owner's full name",
                        text: $ownerName,
                        icon: "person.crop.circle"
                    )
                    
                    ModernTextField(
                        title: "Manager Name",
                        placeholder: "Daily operations manager",
                        text: $managerName,
                        icon: "person.badge.key"
                    )
                    
                    ModernTextField(
                        title: "Primary Email",
                        placeholder: "manager@restaurant.com",
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
                    
                    ModernTextField(
                        title: "Accounting Email",
                        placeholder: "bookkeeper@restaurant.com",
                        text: $accountingEmail,
                        icon: "envelope.badge",
                    )
                }
            }
        }
    }
    
    // MARK: - Validation & Actions
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return selectedOperation != nil && !name.isEmpty && !businessName.isEmpty && !ein.isEmpty && !address.isEmpty
        case 1: return !cuisineTypes.isEmpty && avgDailyCovers > 0 && avgTicketValue > 0
        case 2: return !serviceHours.isEmpty && !kitchenHours.isEmpty && !preferredPickupWindow.isEmpty && !daysOfOperation.isEmpty
        case 3: return !storageCapabilities.isEmpty && !foodSafetyCertifications.isEmpty
        case 4: return estimatedDailyWaste > 0 && estimatedDailyWastePounds > 0 && !donationTypes.isEmpty
        case 5: return !ownerName.isEmpty && !managerName.isEmpty && !contactEmail.isEmpty && !contactPhone.isEmpty && !accountingEmail.isEmpty && phoneValidationError == nil && PhoneValidationService.isValidPhoneNumber(contactPhone)
        default: return true
        }
    }
    
    private var isFormValid: Bool {
        return (0..<steps.count).allSatisfy { step in
            let currentStepBackup = currentStep
            currentStep = step
            let isValid = isCurrentStepValid
            currentStep = currentStepBackup
            return isValid
        }
    }
    
    private func registerRestaurant() {
        guard let operation = selectedOperation else { return }
        
        let restaurant = Restaurant(
            name: name,
            businessName: businessName,
            ein: ein,
            address: address,
            latitude: location.latitude,
            longitude: location.longitude,
            restaurantType: restaurantType,
            avgDailyCovers: Int(avgDailyCovers),
            avgTicketValue: avgTicketValue,
            serviceHours: serviceHours,
            kitchenHours: kitchenHours,
            preferredPickupWindow: preferredPickupWindow,
            ownerName: ownerName,
            managerName: managerName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            accountingEmail: accountingEmail,
            estimatedDailyWaste: estimatedDailyWaste,
            estimatedDailyWastePounds: estimatedDailyWastePounds
        )
        
        // Set additional properties
        restaurant.cuisineTypes = cuisineTypes
        restaurant.annualRevenueRange = annualRevenueRange
        restaurant.daysOfOperation = Array(daysOfOperation)
        restaurant.storageCapabilities = Array(storageCapabilities)
        restaurant.foodSafetyCertifications = Array(foodSafetyCertifications)
        restaurant.healthGrade = healthGrade
        restaurant.donationTypes = Array(donationTypes)
        restaurant.requiresPhotography = requiresPhotography
        restaurant.specialInstructions = specialInstructions
        restaurant.regionalOperation = operation
        
        modelContext.insert(restaurant)
        
        do {
            try modelContext.save()
            HapticFeedback.success()
            showingSuccess = true
        } catch {
            print("Failed to save restaurant: \\(error)")
            HapticFeedback.error()
        }
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
        businessName = ""
        ein = ""
        address = ""
        location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        restaurantType = .casualDining
        cuisineTypes = []
        avgDailyCovers = 100.0
        avgTicketValue = 25.0
        serviceHours = "11:00 AM - 10:00 PM"
        kitchenHours = "11:00 AM - 9:30 PM"
        preferredPickupWindow = "9:30 PM - 10:30 PM"
        daysOfOperation = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        ownerName = ""
        managerName = ""
        contactEmail = ""
        contactPhone = ""
        accountingEmail = ""
        storageCapabilities = [.refrigerated, .hotHolding]
        foodSafetyCertifications = [.servsafe]
        healthGrade = "A"
        estimatedDailyWaste = 200.0
        estimatedDailyWastePounds = 30.0
        donationTypes = ["prepared_meals"]
        requiresPhotography = false
        specialInstructions = ""
        phoneValidationError = nil
    }
}

// MARK: - Helper Views

struct CuisineToggleView: View {
    let cuisine: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            Text(cuisine)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppTheme.Colors.primary.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? AppTheme.Colors.primary : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? AppTheme.Colors.primary : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayToggleView: View {
    let day: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                Text(day)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StorageCapabilityRow: View {
    let capability: StorageCapability
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: capability.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? AppTheme.Colors.primary : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(capability.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.Colors.primary.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CertificationRow: View {
    let certification: FoodSafetyCertification
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .green : .secondary)
                Text(certification.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DonationTypeRow: View {
    let type: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaxBenefitPreviewCard: View {
    let dailyWaste: Double
    let operatingDays: Int
    let onShowCalculator: () -> Void
    
    private var annualWaste: Double {
        dailyWaste * Double(operatingDays) * 52
    }
    
    private var estimatedTaxBenefit: Double {
        annualWaste * 1.15 // 15% enhanced deduction
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("Estimated Tax Benefits")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Calculate", action: onShowCalculator)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Annual Waste Value:")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("$\\(Int(annualWaste))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Enhanced Tax Deduction:")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    Spacer()
                    Text("$\\(Int(estimatedTaxBenefit))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            Text("*Based on 115% enhanced deduction for food donations")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .italic()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Restaurant.self, configurations: config)
    
    RestaurantOnboardingView()
        .modelContainer(container)
}