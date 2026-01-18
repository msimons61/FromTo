//
//  CostComponentEditView.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import SwiftUI

struct CostComponentEditView: View {
    @Environment(\.dismiss) private var dismiss

    let component: CostComponent?
    let onSave: (CostComponent) -> Void
    let tab: AppTab

    @State private var componentType: ComponentType
    @State private var calculationMethod: CalculationMethod
    @State private var displayName: String
    @State private var fixedAmount: Decimal
    @State private var percentageRate: Decimal
    @State private var minimumAmount: Decimal
    @State private var maximumAmount: Decimal
    @State private var isRefundable: Bool
    @State private var creditAmount: Decimal
    @State private var creditValidDays: Int

    @State private var showingValidationAlert = false
    @State private var validationErrors: [String] = []
    @State private var hasChanges = false

    @FocusState private var focusedField: Field?

    private var isNewComponent: Bool {
        component == nil
    }

    enum Field: Hashable {
        case displayName, fixedAmount, percentageRate, minimumAmount, maximumAmount, creditAmount
    }

    init(component: CostComponent?, onSave: @escaping (CostComponent) -> Void, tab: AppTab) {
        self.component = component
        self.onSave = onSave
        self.tab = tab

        // Initialize state from component or defaults
        _componentType = State(initialValue: component?.componentType ?? .transactionCommission)
        _calculationMethod = State(initialValue: component?.calculationMethod ?? .fixedOnly)
        _displayName = State(initialValue: component?.displayName ?? "")
        _fixedAmount = State(initialValue: component?.fixedAmount ?? 0)
        _percentageRate = State(initialValue: component?.percentageRate ?? 0)
        _minimumAmount = State(initialValue: component?.minimumAmount ?? 0)
        _maximumAmount = State(initialValue: component?.maximumAmount ?? 0)
        _isRefundable = State(initialValue: component?.isRefundable ?? false)
        _creditAmount = State(initialValue: component?.creditAmount ?? 0)
        _creditValidDays = State(initialValue: component?.creditValidDays ?? 0)
    }

    var body: some View {
        Form {
            // Component Type Section
            Section {
                Picker("Component Type", selection: $componentType) {
                    ForEach(ComponentType.allCases) { type in
                        Text(type.defaultName).tag(type)
                    }
                }
                .onChange(of: componentType) { _, newType in
                    if displayName.isEmpty || displayName == componentType.defaultName {
                        displayName = newType.defaultName
                    }
                    checkForChanges()
                }

                TextField("Display Name", text: $displayName)
                    .focused($focusedField, equals: .displayName)
                    .onChange(of: displayName) { _, _ in checkForChanges() }

                Text(componentType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Component Type")
            }

            // Calculation Method Section
            Section {
                Picker("Calculation Method", selection: $calculationMethod) {
                    ForEach(CalculationMethod.allCases) { method in
                        Text(method.displayName).tag(method)
                    }
                }
                .onChange(of: calculationMethod) { _, _ in checkForChanges() }

                Text(calculationMethod.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Calculation Method")
            }

            // Cost Parameters Section
            Section {
                if calculationMethod.usesFixed {
                    HStack {
                        Text("Fixed Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $fixedAmount,
                            fractionDigits: 2,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .fixedAmount)
                        .onChange(of: fixedAmount) { _, _ in checkForChanges() }
                    }
                }

                if calculationMethod.usesPercentage {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Percentage Rate")
                            Spacer()
                            DecimalTextFieldNonOptional(
                                label: "Rate",
                                value: $percentageRate,
                                fractionDigits: 4,
                                suffix: "%",
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .percentageRate)
                            .onChange(of: percentageRate) { _, _ in checkForChanges() }
                        }
                        Text("Enter as decimal (e.g., 0.0008 for 0.08%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if calculationMethod.usesMinMax {
                    HStack {
                        Text("Minimum Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $minimumAmount,
                            fractionDigits: 2,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .minimumAmount)
                        .onChange(of: minimumAmount) { _, _ in checkForChanges() }
                    }

                    HStack {
                        Text("Maximum Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $maximumAmount,
                            fractionDigits: 2,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .maximumAmount)
                        .onChange(of: maximumAmount) { _, _ in checkForChanges() }
                    }
                }
            } header: {
                Text("Cost Parameters")
            }

            // Refund/Credit Section
            Section {
                Toggle("Refundable/Credit", isOn: $isRefundable)
                    .onChange(of: isRefundable) { _, _ in checkForChanges() }

                if isRefundable {
                    HStack {
                        Text("Credit Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $creditAmount,
                            fractionDigits: 2,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .creditAmount)
                        .onChange(of: creditAmount) { _, _ in checkForChanges() }
                    }

                    Stepper("Valid for \(creditValidDays) days", value: $creditValidDays, in: 0...365)
                        .onChange(of: creditValidDays) { _, _ in checkForChanges() }
                }
            } header: {
                Text("Refund/Credit")
            } footer: {
                Text("Mark as refundable if this fee can be credited back to the account")
            }
        }
        .navigationTitle(isNewComponent ? "New Component" : "Edit Component")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveComponent()
                }) {
                    Image(systemName: "checkmark")
                        .circleBackground(fgColor: tab.color(), font: .body, padding: 6, prominent: hasChanges)
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
        .alert("Validation Error", isPresented: $showingValidationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }

    private func saveComponent() {
        // Validate
        var errors: [String] = []

        if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Component name is required")
        }

        // Check that at least one cost parameter is set based on calculation method
        switch calculationMethod {
        case .fixedOnly:
            if fixedAmount <= 0 {
                errors.append("Fixed amount must be greater than 0")
            }
        case .percentageOnly:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
        case .fixedPlusPercentage:
            if fixedAmount <= 0 && percentageRate <= 0 {
                errors.append("Either fixed amount or percentage rate must be greater than 0")
            }
        case .percentageWithMinMax:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
            if minimumAmount <= 0 {
                errors.append("Minimum amount must be greater than 0")
            }
        case .monthlyPercentageOfPortfolio:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
        }

        if isRefundable && creditAmount <= 0 {
            errors.append("Credit amount must be greater than 0 for refundable components")
        }

        if !errors.isEmpty {
            validationErrors = errors
            showingValidationAlert = true
            return
        }

        // Create or update component
        let savedComponent: CostComponent
        if let existingComponent = component {
            // Update existing
            existingComponent.componentType = componentType
            existingComponent.calculationMethod = calculationMethod
            existingComponent.displayName = displayName
            existingComponent.fixedAmount = fixedAmount
            existingComponent.percentageRate = percentageRate
            existingComponent.minimumAmount = minimumAmount
            existingComponent.maximumAmount = maximumAmount
            existingComponent.isRefundable = isRefundable
            existingComponent.creditAmount = creditAmount
            existingComponent.creditValidDays = creditValidDays
            savedComponent = existingComponent
        } else {
            // Create new
            savedComponent = CostComponent(
                componentType: componentType,
                calculationMethod: calculationMethod,
                displayName: displayName,
                fixedAmount: fixedAmount,
                percentageRate: percentageRate,
                minimumAmount: minimumAmount,
                maximumAmount: maximumAmount,
                isRefundable: isRefundable,
                creditAmount: creditAmount,
                creditValidDays: creditValidDays
            )
        }

        onSave(savedComponent)
        dismiss()
    }

    private func checkForChanges() {
        let componentTypeChanged = (component?.componentType ?? .transactionCommission) != componentType
        let calculationMethodChanged = (component?.calculationMethod ?? .fixedOnly) != calculationMethod
        let displayNameChanged = (component?.displayName ?? "") != displayName
        let fixedAmountChanged = (component?.fixedAmount ?? 0) != fixedAmount
        let percentageRateChanged = (component?.percentageRate ?? 0) != percentageRate
        let minimumAmountChanged = (component?.minimumAmount ?? 0) != minimumAmount
        let maximumAmountChanged = (component?.maximumAmount ?? 0) != maximumAmount
        let isRefundableChanged = (component?.isRefundable ?? false) != isRefundable
        let creditAmountChanged = (component?.creditAmount ?? 0) != creditAmount
        let creditValidDaysChanged = (component?.creditValidDays ?? 0) != creditValidDays

        hasChanges = componentTypeChanged || calculationMethodChanged || displayNameChanged ||
            fixedAmountChanged || percentageRateChanged || minimumAmountChanged ||
            maximumAmountChanged || isRefundableChanged || creditAmountChanged || creditValidDaysChanged
    }

    // MARK: - Keyboard Navigation
    private func clearCurrentField() {
        switch focusedField {
        case .displayName:
            displayName = ""
        case .fixedAmount:
            fixedAmount = 0
        case .percentageRate:
            percentageRate = 0
        case .minimumAmount:
            minimumAmount = 0
        case .maximumAmount:
            maximumAmount = 0
        case .creditAmount:
            creditAmount = 0
        case .none:
            break
        }
        checkForChanges()
    }

    private func moveToPreviousField() {
        switch focusedField {
        case .displayName, .none:
            focusedField = nil
        case .fixedAmount:
            focusedField = .displayName
        case .percentageRate:
            if calculationMethod.usesFixed {
                focusedField = .fixedAmount
            } else {
                focusedField = .displayName
            }
        case .minimumAmount:
            focusedField = .percentageRate
        case .maximumAmount:
            focusedField = .minimumAmount
        case .creditAmount:
            if calculationMethod.usesMinMax {
                focusedField = .maximumAmount
            } else if calculationMethod.usesPercentage {
                focusedField = .percentageRate
            } else if calculationMethod.usesFixed {
                focusedField = .fixedAmount
            } else {
                focusedField = .displayName
            }
        }
    }

    private func moveToNextField() {
        switch focusedField {
        case .displayName:
            if calculationMethod.usesFixed {
                focusedField = .fixedAmount
            } else if calculationMethod.usesPercentage {
                focusedField = .percentageRate
            } else if calculationMethod.usesMinMax {
                focusedField = .minimumAmount
            } else if isRefundable {
                focusedField = .creditAmount
            } else {
                focusedField = nil
            }
        case .fixedAmount:
            if calculationMethod.usesPercentage {
                focusedField = .percentageRate
            } else if calculationMethod.usesMinMax {
                focusedField = .minimumAmount
            } else if isRefundable {
                focusedField = .creditAmount
            } else {
                focusedField = nil
            }
        case .percentageRate:
            if calculationMethod.usesMinMax {
                focusedField = .minimumAmount
            } else if isRefundable {
                focusedField = .creditAmount
            } else {
                focusedField = nil
            }
        case .minimumAmount:
            focusedField = .maximumAmount
        case .maximumAmount:
            if isRefundable {
                focusedField = .creditAmount
            } else {
                focusedField = nil
            }
        case .creditAmount, .none:
            focusedField = nil
        }
    }
}
