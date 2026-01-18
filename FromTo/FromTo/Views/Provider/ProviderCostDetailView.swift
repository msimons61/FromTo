//
//  ProviderCostDetailView.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import SwiftUI
import SwiftData

struct ProviderCostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tab: AppTab
    let provider: BankBrokerProvider?

    @State private var name: String
    @State private var accountTier: String
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var calculationCurrency: CurrencyBasis
    @State private var startingBalance: Decimal
    @State private var minimumBalanceForTier: Decimal

    @State private var components: [CostComponent]
    @State private var showingComponentEdit = false
    @State private var componentToEdit: CostComponent?
    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var hasChanges = false

    @FocusState private var focusedField: Field?

    private var isNewProvider: Bool {
        provider == nil
    }

    enum Field: Hashable {
        case name, accountTier, startingBalance, minimumBalanceForTier
    }

    init(provider: BankBrokerProvider?, tab: AppTab) {
        self.provider = provider
        self.tab = tab

        // Initialize state from provider or defaults
        _name = State(initialValue: provider?.name ?? "")
        _accountTier = State(initialValue: provider?.accountTier ?? "")
        _startDate = State(initialValue: provider?.startDate ?? Date())
        _hasEndDate = State(initialValue: provider?.endDate != nil)
        _endDate = State(initialValue: provider?.endDate ?? Date())
        _calculationCurrency = State(initialValue: provider?.calculationCurrency ?? .transaction)
        _startingBalance = State(initialValue: provider?.startingBalance ?? 0)
        _minimumBalanceForTier = State(initialValue: provider?.minimumBalanceForTier ?? 0)
        _components = State(initialValue: provider?.costComponents ?? [])
    }

    var body: some View {
        Form {
            // Provider Details Section
            Section {
                TextField("Provider Name", text: $name)
                    .focused($focusedField, equals: .name)
                    .onChange(of: name) { _, _ in checkForChanges() }
                TextField("Account Tier (Optional)", text: $accountTier)
                    .focused($focusedField, equals: .accountTier)
                    .onChange(of: accountTier) { _, _ in checkForChanges() }

                HStack {
                    Text("Starting Balance")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Amount",
                        value: $startingBalance,
                        fractionDigits: 2,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .startingBalance)
                    .onChange(of: startingBalance) { _, _ in checkForChanges() }
                }

                HStack {
                    Text("Minimum Balance for Tier")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Amount",
                        value: $minimumBalanceForTier,
                        fractionDigits: 2,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .minimumBalanceForTier)
                    .onChange(of: minimumBalanceForTier) { _, _ in checkForChanges() }
                }

                Picker("Calculation Currency", selection: $calculationCurrency) {
                    ForEach(CurrencyBasis.allCases) { basis in
                        Text(basis.displayName).tag(basis)
                    }
                }
                .onChange(of: calculationCurrency) { _, _ in checkForChanges() }
            } header: {
                Text("Provider Details")
            } footer: {
                Text(calculationCurrency.description)
            }

            // Active Period Section
            Section {
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .onChange(of: startDate) { _, _ in checkForChanges() }

                Toggle("Has End Date", isOn: $hasEndDate)
                    .onChange(of: hasEndDate) { _, _ in checkForChanges() }

                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .onChange(of: endDate) { _, _ in checkForChanges() }
                }
            } header: {
                Text("Active Period")
            }

            // Cost Components Section
            Section {
                if components.isEmpty {
                    Text("No components added yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(components) { component in
                        Button {
                            componentToEdit = component
                            showingComponentEdit = true
                        } label: {
                            CostComponentRowView(component: component)
                        }
                        .foregroundColor(.primary)
                    }
                    .onDelete(perform: deleteComponents)
                }

                Button {
                    componentToEdit = nil
                    showingComponentEdit = true
                } label: {
                    Label("Add Component", systemImage: "plus.circle")
                }
            } header: {
                Text("Cost Components")
            } footer: {
                Text("Add cost components to define the fee structure for this provider")
            }
        }
        .navigationTitle(isNewProvider ? "New Provider" : "Edit Provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .circleBackground(fgColor: tab.color(), font: .body, padding: KeyboardToolbarButton.clear.padding)
                }
            }
            
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button("Cancel") {
//                    dismiss()
//                }
//            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveProvider()
                }) {
                    Image(systemName: "checkmark")
                        .circleBackground(fgColor: tab.color(), font: .body, padding: KeyboardToolbarButton.clear.padding, prominent: hasChanges)
//                        .circleBackground(fgColor: tab.color(), font: .body, padding: 6, prominent: hasChanges)
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                KeyboardToolbarButton.button(.clear) { clearCurrentField() }

                Spacer()

                KeyboardToolbarButton.button(.previous) { moveToPreviousField() }

                KeyboardToolbarButton.button(.next) { moveToNextField() }

                KeyboardToolbarButton.button(.done(tab.color())) { focusedField = nil }
            }
        }
        .sheet(isPresented: $showingComponentEdit) {
            NavigationStack {
                CostComponentEditView(
                    component: componentToEdit,
                    onSave: { savedComponent in
                        if let index = components.firstIndex(where: { $0.id == savedComponent.id }) {
                            components[index] = savedComponent
                        } else {
                            components.append(savedComponent)
                        }
                        checkForChanges()
                    },
                    tab: tab
                )
            }
        }
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }

    private func deleteComponents(at offsets: IndexSet) {
        components.remove(atOffsets: offsets)
        checkForChanges()
    }

    private func saveProvider() {
        // Validate
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Provider name is required")
        }

        if startingBalance <= 0 {
            errors.append("Starting balance must be greater than 0")
        }

        if components.isEmpty {
            errors.append("At least one cost component is required")
        }

        if hasEndDate && endDate <= startDate {
            errors.append("End date must be after start date")
        }

        if !errors.isEmpty {
            validationErrors = errors
            showingValidationAlert = true
            return
        }

        // Save
        if let existingProvider = provider {
            // Update existing provider
            existingProvider.name = name
            existingProvider.accountTier = accountTier
            existingProvider.startDate = startDate
            existingProvider.endDate = hasEndDate ? endDate : nil
            existingProvider.calculationCurrency = calculationCurrency
            existingProvider.startingBalance = startingBalance
            existingProvider.minimumBalanceForTier = minimumBalanceForTier

            // Update components
            // Remove old components
            for component in existingProvider.costComponents ?? [] {
                modelContext.delete(component)
            }

            // Add new components
            for component in components {
                modelContext.insert(component)
                existingProvider.addComponent(component)
            }
        } else {
            // Create new provider
            let newProvider = BankBrokerProvider(
                name: name,
                accountTier: accountTier,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                calculationCurrency: calculationCurrency,
                minimumBalanceForTier: minimumBalanceForTier,
                startingBalance: startingBalance
            )

            modelContext.insert(newProvider)

            // Add components
            for component in components {
                modelContext.insert(component)
                newProvider.addComponent(component)
            }
        }

        try? modelContext.save()
        dismiss()
    }

    private func checkForChanges() {
        let nameChanged = (provider?.name ?? "") != name
        let accountTierChanged = (provider?.accountTier ?? "") != accountTier
        let startDateChanged = (provider?.startDate ?? Date()) != startDate
        let hasEndDateChanged = (provider?.endDate != nil) != hasEndDate
        let endDateChanged = (provider?.endDate ?? Date()) != endDate
        let calculationCurrencyChanged = (provider?.calculationCurrency ?? .transaction) != calculationCurrency
        let startingBalanceChanged = (provider?.startingBalance ?? 0) != startingBalance
        let minimumBalanceChanged = (provider?.minimumBalanceForTier ?? 0) != minimumBalanceForTier

        // Check components (simplified - could be more sophisticated)
        let componentsChanged = (provider?.costComponents ?? []).count != components.count

        hasChanges = nameChanged || accountTierChanged || startDateChanged || hasEndDateChanged ||
            endDateChanged || calculationCurrencyChanged || startingBalanceChanged ||
            minimumBalanceChanged || componentsChanged
    }

    // MARK: - Keyboard Navigation
    private func clearCurrentField() {
        switch focusedField {
        case .name:
            name = ""
        case .accountTier:
            accountTier = ""
        case .startingBalance:
            startingBalance = 0
        case .minimumBalanceForTier:
            minimumBalanceForTier = 0
        case .none:
            break
        }
        checkForChanges()
    }

    private func moveToPreviousField() {
        switch focusedField {
        case .accountTier:
            focusedField = .name
        case .startingBalance:
            focusedField = .accountTier
        case .minimumBalanceForTier:
            focusedField = .startingBalance
        case .name, .none:
            focusedField = nil
        }
    }

    private func moveToNextField() {
        switch focusedField {
        case .name:
            focusedField = .accountTier
        case .accountTier:
            focusedField = .startingBalance
        case .startingBalance:
            focusedField = .minimumBalanceForTier
        case .minimumBalanceForTier, .none:
            focusedField = nil
        }
    }
}
