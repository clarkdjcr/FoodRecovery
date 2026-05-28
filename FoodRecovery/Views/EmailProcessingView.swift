//
//  EmailProcessingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftData
import SwiftUI

struct EmailProcessingView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var viewModel: RegionalOperationViewModel = RegionalOperationViewModel()
  @State private var selectedOperation: RegionalOperation?
  @State private var emailSubject = ""
  @State private var emailBody = ""
  @State private var fromEmail = "donc542@me.com"
  @State private var isProcessing = false
  @State private var processingResult: EmailProcessingResult?
  @State private var showingResult = false
  @State private var errorMessage: String?


  var body: some View {
    // NavigationView {
      Form {
        Section {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "brain")
                .foregroundColor(.blue)
              Text("Intelligent Processing Powered")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            }
            Text("Uses advanced pattern matching for privacy-focused email analysis. Ready for Apple Foundation Models when available.")
              .font(.caption)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }
        }
        
        Section("Select Operation") {
          Picker("Operation", selection: $selectedOperation) {
            Text("Select an operation").tag(nil as RegionalOperation?)
            ForEach(viewModel.operations, id: \.id) { operation in
              Text(operation.name).tag(operation as RegionalOperation?)
            }
          }
          .pickerStyle(MenuPickerStyle())
        }

        Section {
          TextField("From Email", text: $fromEmail)
            .textFieldStyle(RoundedBorderTextFieldStyle())

          TextField("Email Subject", text: $emailSubject)
            .textFieldStyle(RoundedBorderTextFieldStyle())

          VStack(alignment: .leading, spacing: 8) {
            Text("Email Body")
              .font(.headline)
            TextEditor(text: $emailBody)
              .frame(minHeight: 150)
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.gray.opacity(0.3), lineWidth: 1)
              )
          }
        } header: {
          Text("Email Details")
        }

        Section {
          Button("Process Email with AI") {
            processEmail()
          }
          .buttonStyle(.borderedProminent)
          .disabled(
            selectedOperation == nil || emailSubject.isEmpty || emailBody.isEmpty
              || fromEmail.isEmpty || isProcessing)
          
          Button("Load Sample Email") {
            loadSampleEmail()
          }
          .buttonStyle(.bordered)
        }

        if isProcessing {
          Section {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Processing email with intelligent analysis...")
                .font(.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
          }
        }

        if let error = errorMessage {
          Section {
            Text(error)
              .foregroundColor(.red)
              .font(.body)
          }
        }
      }
      .navigationTitle("Smart Email Processing")
      .sheet(isPresented: $showingResult) {
        if let result = processingResult, let operation = selectedOperation {
          EmailProcessingResultView(
            result: result,
            operation: operation,
            emailSubject: emailSubject,
            emailBody: emailBody,
            fromEmail: fromEmail,
            viewModel: viewModel
          )
        }
      }
      .onAppear {
        viewModel.loadOperations(modelContext: modelContext)
      }
    }
    
    // MARK: - Private Functions
    
    private func processEmail() {
    guard selectedOperation != nil else { return }

    isProcessing = true
    errorMessage = nil

    Task {
      do {
        let emailService = EmailProcessingService()
        let result = try await emailService.processDonationEmail(
          subject: emailSubject,
          body: emailBody,
          fromEmail: fromEmail
        )

        await MainActor.run {
          processingResult = result
          isProcessing = false
          showingResult = true
        }
      } catch {
        await MainActor.run {
          errorMessage = "Failed to process email: \(error.localizedDescription)"
          isProcessing = false
        }
      }
    }
  }
  
  private func loadSampleEmail() {
    emailSubject = "Food Donation Available - Fresh Produce"
    emailBody = """
    Dear Food Recovery Team,

    We have approximately 25 pounds of fresh produce available for donation today. This includes:

    - 8 pounds of mixed lettuce and leafy greens
    - 6 pounds of tomatoes 
    - 4 pounds of carrots
    - 3 pounds of bell peppers
    - 4 pounds of broccoli

    All items are still fresh but approaching their sell-by dates. Most items are good until December 20th, 2025. 

    Please let me know if you can arrange pickup by 6 PM today.

    Best regards,
    Sarah Johnson
    Store Manager
    Fresh Market Grocery
    """
  }

  struct EmailProcessingResultView: View {
    let result: EmailProcessingResult
    let operation: RegionalOperation
    let emailSubject: String
    let emailBody: String
    let fromEmail: String
    let viewModel: RegionalOperationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isManuallyVerified = false

    var matchingStore: GroceryStore? {
      operation.groceryStores.first { $0.donationEmail == fromEmail }
    }

  var body: some View {
    // NavigationView {
      Form {
        Section("AI Processing Results") {
          HStack {
            Text("Food Type")
            Spacer()
            Text(result.foodType.rawValue.capitalized)
              .fontWeight(.medium)
          }

          HStack {
            Text("Quantity")
            Spacer()
            Text("\(result.quantity, specifier: "%.1f") lbs")
              .fontWeight(.medium)
          }

          if let expirationDate = result.expirationDate {
            HStack {
              Text("Expiration Date")
              Spacer()
              Text(expirationDate, style: .date)
                .fontWeight(.medium)
            }
          }

          HStack {
            Text("Confidence")
            Spacer()
            Text("\(result.confidence * 100, specifier: "%.0f")%")
              .fontWeight(.medium)
              .foregroundColor(result.confidence > 0.8 ? .green : .orange)
          }
          
          Toggle(isOn: $isManuallyVerified) {
              HStack {
                  Image(systemName: isManuallyVerified ? "checkmark.shield.fill" : "shield")
                      .foregroundColor(isManuallyVerified ? .green : .gray)
                  Text("Verify Accuracy")
                      .fontWeight(.medium)
              }
          }
        }

        Section("Description") {
          Text(result.foodDescription)
            .font(.body)
        }

        Section("Store Assignment") {
          if let store = matchingStore {
            HStack {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
              Text("Matched to: \(store.name)")
                .fontWeight(.medium)
            }
          } else {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
              Text("No matching store found")
                .fontWeight(.medium)
            }
            Text("Please verify the email address matches a registered store.")
              .font(.caption)
              .foregroundColor(AppTheme.Colors.textSecondary)
          }
        }

        Section {
          Button("Create Donation Record") {
            createDonation()
          }
          .buttonStyle(.borderedProminent)
          .disabled(matchingStore == nil)
        }
      }
      .navigationTitle("Processing Results")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    
    private func createDonation() {
      guard let store = matchingStore else { return }

      let donation = Donation(
        foodType: result.foodType,
        quantity: result.quantity,
        expirationDate: result.expirationDate,
        description: result.foodDescription,
        emailSource: fromEmail,
        emailSubject: emailSubject,
        emailBody: emailBody,
        aiExtractedData: "{\"confidence\": \(result.confidence)}",
        aiConfidence: result.confidence,
        isVerified: isManuallyVerified
      )

      donation.groceryStore = store
      store.donations.append(donation)

      modelContext.insert(donation)

      // Schedule expiry alert if the donation has an expiration date
      if let expiryDate = result.expirationDate {
        Task {
          NotificationService.shared.scheduleDonationExpiryAlert(
            donationId: donation.id,
            description: result.foodDescription,
            storeName: store.name,
            expiryDate: expiryDate
          )
        }
      }

      do {
        try modelContext.save()
        dismiss()
      } catch {
        // Handle error
      }
    }
  }
}

#Preview {
  EmailProcessingView()
}
