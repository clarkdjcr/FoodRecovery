// BulkNotificationView.swift
// Lets the operator compose a single message and send it via the
// system SMS composer to multiple food providers and/or food banks.

import SwiftUI

struct BulkNotificationView: View {
    let operation: RegionalOperation
    @Environment(\.dismiss) private var dismiss

    @State private var messageText = ""
    @State private var selectedProviderIDs: Set<UUID> = []
    @State private var selectedBankIDs: Set<UUID> = []

    private var selectedCount: Int { selectedProviderIDs.count + selectedBankIDs.count }

    private var selectedPhoneNumbers: [String] {
        let providerPhones = operation.foodProviders
            .filter { selectedProviderIDs.contains($0.id) }
            .map { $0.contactPhone }
        let bankPhones = operation.foodBanks
            .filter { selectedBankIDs.contains($0.id) }
            .map { $0.contactPhone }
        return (providerPhones + bankPhones).filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Type your message…", text: $messageText, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("Message")
                } footer: {
                    Text("Opens the system Messages app with all selected contacts pre-filled.")
                        .font(.caption)
                }

                if !operation.foodProviders.isEmpty {
                    Section("Food Providers (\(operation.foodProviders.count))") {
                        ForEach(operation.foodProviders) { provider in
                            ContactRow(
                                name: provider.name,
                                phone: provider.contactPhone,
                                isSelected: selectedProviderIDs.contains(provider.id)
                            ) {
                                toggle(provider.id, in: &selectedProviderIDs)
                            }
                        }
                    }
                }

                if !operation.foodBanks.isEmpty {
                    Section("Food Banks (\(operation.foodBanks.count))") {
                        ForEach(operation.foodBanks) { bank in
                            ContactRow(
                                name: bank.name,
                                phone: bank.contactPhone,
                                isSelected: selectedBankIDs.contains(bank.id)
                            ) {
                                toggle(bank.id, in: &selectedBankIDs)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bulk Notification")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        InstantMessagingService.shared.composeBulkSMS(
                            to: selectedPhoneNumbers,
                            message: messageText
                        )
                        dismiss()
                    } label: {
                        Label("Open in Messages", systemImage: "message.fill")
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCount == 0 || messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedCount > 0 {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("\(selectedCount) recipient\(selectedCount == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Select All") { selectAll() }
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.bar)
                } else {
                    HStack {
                        Text("Select recipients below")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Select All") { selectAll() }
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.bar)
                }
            }
        }
    }

    private func toggle(_ id: UUID, in set: inout Set<UUID>) {
        if set.contains(id) { set.remove(id) } else { set.insert(id) }
    }

    private func selectAll() {
        selectedProviderIDs = Set(operation.foodProviders.map { $0.id })
        selectedBankIDs = Set(operation.foodBanks.map { $0.id })
    }
}

// MARK: - Row

private struct ContactRow: View {
    let name: String
    let phone: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .foregroundColor(.primary)
                        .fontWeight(isSelected ? .medium : .regular)
                    if !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
