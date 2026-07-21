//
//  OnboardingProgressView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 7/12/26.
//

import SwiftUI

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var progress: Double {
        Double(currentStep) / Double(totalSteps - 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    if index < totalSteps - 1 {
                        // Step circle
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(index <= currentStep ? .white : .gray)
                            )
                        
                        // Connecting line
                        Rectangle()
                            .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Final step circle
                        Circle()
                            .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(index <= currentStep ? .white : .gray)
                            )
                    }
                }
            }
            
            // Step titles
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    if index < stepTitles.count {
                        Text(stepTitles[index])
                            .font(.caption)
                            .fontWeight(index == currentStep ? .semibold : .regular)
                            .foregroundColor(index == currentStep ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Setup Completion Indicator

struct SetupCompletionIndicator: View {
    let operation: RegionalOperation
    @State private var showingDetails = false
    
    private var completionPercentage: Double {
        var completed = 0.0
        var total = 0.0
        
        // Check operation details (25%)
        total += 1
        if !operation.name.isEmpty { completed += 0.25 }
        
        // Check food banks (25%)
        total += 1
        if operation.foodBanks.count >= 1 { completed += 0.25 }
        
        // Check food providers (25%)
        total += 1
        if operation.foodProviders.count >= 1 { completed += 0.25 }
        
        // Check if routes have been generated (25%)
        total += 1
        if operation.pickupRoutes.count >= 1 { completed += 0.25 }
        
        return (completed / total) * 100
    }
    
    private var status: SetupStatus {
        let percentage = completionPercentage
        if percentage == 100 { return .complete }
        if percentage >= 50 { return .inProgress }
        return .started }
    
    private var missingItems: [String] {
        var items: [String] = []
        
        if operation.name.isEmpty { items.append("Operation name") }
        if operation.foodBanks.isEmpty { items.append("Food banks") }
        if operation.foodProviders.isEmpty { items.append("Food providers") }
        if operation.pickupRoutes.isEmpty { items.append("Generated routes") }
        
        return items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                Text("Setup Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(completionPercentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(status.color)
            }
            
            // Progress bar
            ProgressView(value: completionPercentage / 100)
                .tint(status.color)
            
            // Status message
            HStack {
                Text(status.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if !missingItems.isEmpty {
                    Button("View Details") {
                        showingDetails = true
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showingDetails) {
            SetupDetailsSheet(missingItems: missingItems, completionPercentage: completionPercentage)
        }
    }
}

enum SetupStatus {
    case started
    case inProgress
    case complete
    
    var icon: String {
        switch self {
        case .started: return "circle.dashed"
        case .inProgress: return "circle.fill"
        case .complete: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .started: return .orange
        case .inProgress: return .blue
        case .complete: return .green
        }
    }
    
    var message: String {
        switch self {
        case .started: return "Get started by adding your operation details"
        case .inProgress: return "You're making progress! Keep going."
        case .complete: return "Setup complete! You're ready to start rescuing food."
        }
    }
}

struct SetupDetailsSheet: View {
    let missingItems: [String]
    let completionPercentage: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Overall progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall Progress")
                        .font(.headline)
                    HStack {
                        Text("\(Int(completionPercentage))% Complete")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    ProgressView(value: completionPercentage / 100)
                        .tint(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                
                // Missing items
                if !missingItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("To Complete Setup")
                            .font(.headline)
                        ForEach(missingItems, id: \.self) { item in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(item)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title)
                            Text("All Setup Complete!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        Text("Your operation is fully configured and ready to go.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Setup Details")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressView(
            currentStep: 1,
            totalSteps: 3,
            stepTitles: ["Operation Details", "Configure Region", "Set Schedule"]
        )
        
        OnboardingProgressView(
            currentStep: 2,
            totalSteps: 4,
            stepTitles: ["Basic Info", "Location", "Partners", "Schedule"]
        )
    }
    .padding()
}
