//
//  BankBrokerCostDetailView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct BankBrokerCostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allProviders: [BankBrokerCost]

    let provider: BankBrokerCost
    let tab: AppTab

    // Draft copies for editing
    @State private var bankBrokerName: String
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var hasEndDate: Bool
    @State private var fixedCost: Decimal
    @State private var variableCostRate: Decimal
    @State private var maximumCost: Decimal

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false
    @State private var showingConflictAlert = false
    @State private var conflictingProviderEndDate: Date?

    enum Field: Hashable {
        case bankBrokerName
        case fixedCost
        case variableCostRate
        case maximumCost
    }

    init(provider: BankBrokerCost, tab: AppTab) {
        self.provider = provider
        self.tab = tab

        // Initialize draft state from provider model
        _bankBrokerName = State(initialValue: provider.bankBrokerName)
        _startDate = State(initialValue: provider.startDate)
        _endDate = State(initialValue: provider.endDate)
        _hasEndDate = State(initialValue: provider.endDate != nil)
        _fixedCost = State(initialValue: provider.fixedCost)
        _variableCostRate = State(initialValue: provider.variableCostRate)
        _maximumCost = State(initialValue: provider.maximumCost)
    }

    var body: some View {
        Form {
            // MARK: - Details Section
            Section {
                HStack {
                    TextField("Bank/Broker Name", text: $bankBrokerName)
                        .focused($focusedField, equals: .bankBrokerName)
                        .onChange(of: bankBrokerName) { _, _ in hasChanges = true }

                    if !bankBrokerName.isEmpty {
                        Button(action: {
                            bankBrokerName = ""
                            hasChanges = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if bankBrokerName.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Bank/Broker name is required")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            } header: {
                Text("Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Active Period Section
            Section {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .onChange(of: startDate) { _, _ in hasChanges = true }

                Toggle("Has End Date", isOn: $hasEndDate)
                    .onChange(of: hasEndDate) { _, newValue in
                        if newValue && endDate == nil {
                            endDate = Date()
                        } else if !newValue {
                            endDate = nil
                        }
                        hasChanges = true
                    }

                if hasEndDate {
                    DatePicker("End Date", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                    .onChange(of: endDate) { _, _ in hasChanges = true }
                }

                // Validation for date order
                if let end = endDate, startDate > end {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Start date must be before or equal to end date")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            } header: {
                Text("Active Period")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Cost Structure Section
            Section {
                HStack {
                    Text("Fixed Cost")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Fixed Cost",
                        value: $fixedCost,
                        fractionDigits: 2,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .fixedCost)
                    .onChange(of: fixedCost) { _, _ in hasChanges = true }
                }

                HStack {
                    Text("Variable Cost Rate")
                    Spacer()
                    PercentageTextField(
                        label: "Rate",
                        tab: tab,
                        value: $variableCostRate
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .variableCostRate)
                    .onChange(of: variableCostRate) { _, _ in hasChanges = true }
                }

                HStack {
                    Text("Maximum Cost")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Maximum",
                        value: $maximumCost,
                        fractionDigits: 2,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .maximumCost)
                    .onChange(of: maximumCost) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Cost Structure")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Information Section
            Section {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(provider.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Modified")
                    Spacer()
                    Text(provider.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Information")
                    .foregroundStyle(tab.color())
            }
        }
        .navigationTitle("Provider Cost")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges || !isValid)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Button(action: { clearCurrentField() }) {
                    Text("Clear")
                        .kbCapsuleBackground(color: .red)
                }

                Spacer()

                Button(action: { moveToPreviousField() }) {
                    Image(systemName: "chevron.up")
                        .kbCapsuleBackground(color: .teal)
                }

                Button(action: { moveToNextField() }) {
                    Image(systemName: "chevron.down")
                        .kbCapsuleBackground(color: .blue)
                }

                Button(action: { focusedField = nil }) {
                    Text("Done")
                        .kbCapsuleBackground(color: .green)
                }
            }
        }
        .alert("Active Provider Exists", isPresented: $showingConflictAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let endDate = conflictingProviderEndDate {
                Text("There is already an active provider cost record for '\(bankBrokerName)' ending on \(endDate.formatted(date: .long, time: .omitted)). You must end that record first before creating a new active one.")
            } else {
                Text("There is already an active provider cost record for '\(bankBrokerName)' with no end date. You must end that record first before creating a new active one.")
            }
        }
    }

    // MARK: - Validation
    private var isValid: Bool {
        guard !bankBrokerName.isEmpty else { return false }
        guard fixedCost >= 0, variableCostRate >= 0, maximumCost >= 0 else { return false }
        if let end = endDate {
            return startDate <= end
        }
        return true
    }

    // MARK: - Actions
    private func saveChanges() {
        // Check for conflicting active records (same bank/broker with overlapping period)
        if let conflict = checkForConflict() {
            conflictingProviderEndDate = conflict.endDate
            showingConflictAlert = true
            return
        }

        provider.bankBrokerName = bankBrokerName
        provider.startDate = startDate
        provider.endDate = hasEndDate ? endDate : nil
        provider.fixedCost = fixedCost
        provider.variableCostRate = variableCostRate
        provider.maximumCost = maximumCost
        provider.modifiedAt = Date()

        try? modelContext.save()
        hasChanges = false
        dismiss()
    }

    private func checkForConflict() -> BankBrokerCost? {
        // Get the effective end date for this provider
        let thisEndDate = hasEndDate ? endDate : nil

        // Find any other provider with the same name that would overlap
        return allProviders.first { otherProvider in
            // Skip checking against itself
            guard otherProvider.id != provider.id else { return false }

            // Must have same name
            guard otherProvider.bankBrokerName.lowercased() == bankBrokerName.lowercased() else { return false }

            // Check if the other provider is active (no end date or end date in the future)
            let otherEndDate = otherProvider.endDate
            let now = Date()

            // If other provider has no end date or end date is in the future, it's active
            let otherIsActive = otherEndDate == nil || otherEndDate! >= now

            // If we're trying to create/update a record with no end date or future end date
            let thisWillBeActive = thisEndDate == nil || thisEndDate! >= now

            // Both would be active = conflict
            return otherIsActive && thisWillBeActive
        }
    }

    // MARK: - Keyboard Navigation
    private func moveToPreviousField() {
        switch focusedField {
        case .fixedCost:
            focusedField = .bankBrokerName
        case .variableCostRate:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCostRate
        default:
            focusedField = nil
        }
    }

    private func moveToNextField() {
        switch focusedField {
        case .bankBrokerName:
            focusedField = .fixedCost
        case .fixedCost:
            focusedField = .variableCostRate
        case .variableCostRate:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil
        case .none:
            focusedField = .bankBrokerName
        }
    }

    private func clearCurrentField() {
        switch focusedField {
        case .bankBrokerName:
            bankBrokerName = ""
        case .fixedCost:
            fixedCost = 0
        case .variableCostRate:
            variableCostRate = 0
        case .maximumCost:
            maximumCost = 0
        default:
            break
        }
        hasChanges = true
    }
}
