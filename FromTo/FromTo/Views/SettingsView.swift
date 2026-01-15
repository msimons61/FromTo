//
//  SettingsView.swift
//  FromTo
//
//  Updated by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsQuery: [Settings]
    @Query private var allProviders: [BankBrokerCost]
    @FocusState private var focusedField: Field?
    let tab: AppTab

    // Draft state for settings
    @State private var displayMode: DisplayMode = .system
    @State private var doubleCurrency: Bool = true
    @State private var baseCurrency: String = "USD"
    @State private var transactionCurrency: String = "EUR"
    @State private var applyCost: Bool = true
    @State private var bankBrokerName: String = ""
    @State private var defaultFixedCost: Decimal = 0
    @State private var defaultVariableCost: Decimal = 0
    @State private var defaultMaximumCost: Decimal? = nil
    @State private var showingInvalidProviderAlert = false
    @State private var showingNoBrokerWithCostAlert = false
    @State private var showingSameCurrencyAlert = false

    private var settings: Settings? {
        settingsQuery.first
    }

    // Get unique provider names
    private var uniqueProviderNames: [String] {
        let names = allProviders.map { $0.bankBrokerName }
        return Array(Set(names)).sorted()
    }

    // MARK: - Filtered Currency Lists
    /// Available base currencies (excludes transaction currency when double currency is enabled)
    private var availableBaseCurrencies: [String] {
        let currencies = settings?.availableCurrencies ?? []
        guard doubleCurrency else { return currencies }
        return currencies.filter { $0 != transactionCurrency }
    }

    /// Available transaction currencies (always excludes base currency)
    private var availableTransactionCurrencies: [String] {
        let currencies = settings?.availableCurrencies ?? []
        return currencies.filter { $0 != baseCurrency }
    }

    // MARK: - App Information
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Appearance Section
                Section {
                    Picker("Display Mode", selection: $displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(tab.color())
                    .onChange(of: displayMode) { _, _ in saveSettings() }
                } header: {
                    Text("Appearance")
                        .foregroundStyle(tab.color())
                }

                // MARK: - Currency Section
                Section {
                    Toggle("Double Currency", isOn: $doubleCurrency)
                        .onChange(of: doubleCurrency) { _, newValue in
                            if !newValue {
                                // When disabling, sync to same currency
                                transactionCurrency = baseCurrency
                            } else {
                                // When enabling, ensure currencies are different
                                if baseCurrency == transactionCurrency {
                                    // Auto-change to first available different currency
                                    if let firstDifferent = availableTransactionCurrencies.first {
                                        transactionCurrency = firstDifferent
                                        showingSameCurrencyAlert = true
                                    }
                                }
                            }
                            saveSettings()
                        }

                    NavigationLink(
                        destination: CurrencySelectionView(
                            selectedCurrency: $baseCurrency,
                            availableCurrencies: availableBaseCurrencies,
                            title: doubleCurrency ? "Base Currency" : "Currency",
                            tab: tab
                        )
                    ) {
                        HStack {
                            Text(doubleCurrency ? "Base Currency" : "Currency")
                            Spacer()
                            Text(baseCurrency)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: baseCurrency) { _, _ in saveSettings() }

                    if doubleCurrency {
                        NavigationLink(
                            destination: CurrencySelectionView(
                                selectedCurrency: $transactionCurrency,
                                availableCurrencies: availableTransactionCurrencies,
                                title: "Transaction Currency",
                                tab: tab
                            )
                        ) {
                            HStack {
                                Text("Transaction Currency")
                                Spacer()
                                Text(transactionCurrency)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: transactionCurrency) { _, _ in saveSettings() }
                    }

                } header: {
                    HStack {
                        Text("Currency")
                            .foregroundStyle(tab.color())
                        Spacer()
                        if doubleCurrency {
                            Button(action: {
                                swapCurrencies()
                            }) {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .circleBackground(fgColor: tab.color(), font: .body.bold(), padding: 5)
                            }
                        }
                    }
                }

                // MARK: - Bank/Broker Section
                Section {
                    if applyCost && !uniqueProviderNames.isEmpty {
                        NavigationLink(
                            destination: ProviderSelectionView(
                                selectedProvider: $bankBrokerName,
                                availableProviders: uniqueProviderNames,
                                tab: tab
                            )
                        ) {
                            HStack {
                                Text("Default Bank/Broker")
                                Spacer()
                                Text(bankBrokerName.isEmpty ? "None" : bankBrokerName)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: bankBrokerName) { _, newValue in
                            // Check for logical inconsistency: Apply Cost enabled but no broker selected
                            if applyCost && newValue.isEmpty {
                                showingNoBrokerWithCostAlert = true
                            } else {
                                loadCostsFromProvider(newValue)
                            }
                            saveSettings()
                        }
                    } else {
                        HStack {
                            TextField("Bank/Broker Name", text: $bankBrokerName)
                                .focused($focusedField, equals: .bankBrokerName)
                                .onChange(of: bankBrokerName) { _, _ in saveSettings() }
                        }
                    }
                } header: {
                    Text("Default Bank/Broker")
                        .foregroundStyle(tab.color())
                }

                // MARK: - Default Cost Section
                Section {
                    Toggle("Apply Cost", isOn: $applyCost)
                        .onChange(of: applyCost) { _, newValue in
                            if !newValue {
                                defaultFixedCost = 0
                                defaultVariableCost = 0
                                defaultMaximumCost = nil
                            } else {
                                // When turning ON, validate that bankBrokerName is in provider list
                                if !bankBrokerName.isEmpty && !uniqueProviderNames.isEmpty {
                                    if !uniqueProviderNames.contains(where: { $0.lowercased() == bankBrokerName.lowercased() }) {
                                        showingInvalidProviderAlert = true
                                    }
                                }
                            }
                            saveSettings()
                        }

                    if applyCost {
                        NavigationLink(destination: BankBrokerCostListView(tab: tab)) {
                            HStack {
                                Text("Manage Provider Costs")
                                Spacer()
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Fixed Cost")
                            Spacer()
                            DecimalTextFieldNonOptional(
                                label: "Fixed",
                                value: $defaultFixedCost,
                                fractionDigits: 2,
                                suffix: baseCurrency,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .fixedCost)
                            .onChange(of: defaultFixedCost) { _, _ in saveSettings() }
                        }

                        HStack {
                            Text("Variable Cost")
                            Spacer()
                            PercentageTextField(
                                label: "Variable",
                                tab: tab,
                                value: $defaultVariableCost
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .variableCost)
                            .onChange(of: defaultVariableCost) { _, _ in saveSettings() }
                        }

                        HStack {
                            Text("Maximum Cost")
                            Spacer()
                            DecimalTextField(
                                label: "Maximum",
                                value: $defaultMaximumCost,
                                fractionDigits: 2,
                                suffix: baseCurrency,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .maximumCost)
                            .onChange(of: defaultMaximumCost) { _, _ in saveSettings() }
                        }
                    } else {
                        Text("Cost application is disabled")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                } header: {
                    Text("Default Cost")
                        .foregroundStyle(tab.color())
                }

                // MARK: - Information Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(appBuild)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Information")
                        .foregroundStyle(tab.color())
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        clearCurrentField()
                    }) {
                        Text("Clear")
                            .kbCapsuleBackground(color: .red)
                    }

                    Spacer()

                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .kbCapsuleBackground(color: .teal)
                    }

                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .kbCapsuleBackground(color: .blue)
                    }

                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .kbCapsuleBackground(color: .green)
                    }
                }
            }
            .tint(tab.color())
            .onAppear {
                loadSettings()
            }
            .alert("Invalid Bank/Broker", isPresented: $showingInvalidProviderAlert) {
                Button("OK", role: .cancel) {
                    // User acknowledged, they can manually select correct one
                }
            } message: {
                Text("The current Default Bank/Broker '\(bankBrokerName)' is not in your Provider Costs list. Please select a valid Bank/Broker from the list to use cost features.")
            }
            .alert("No Bank/Broker Selected", isPresented: $showingNoBrokerWithCostAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Apply Cost is enabled but no Default Bank/Broker is selected. This is a logical inconsistency. Please select a Bank/Broker to use cost features, or disable Apply Cost.")
            }
            .alert("Same Currency Not Allowed", isPresented: $showingSameCurrencyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The Frankfurter API does not support the same currency for both Base Currency and Transaction Currency. The Transaction Currency has been automatically changed to \(transactionCurrency).")
            }
        }
    }

    enum Field: Hashable {
        case bankBrokerName, fixedCost, variableCost, maximumCost
    }

    // MARK: - Helper Methods
    private func loadSettings() {
        if let settings = settings {
            displayMode = settings.displayMode
            doubleCurrency = settings.doubleCurrency
            baseCurrency = settings.baseCurrency
            transactionCurrency = settings.transactionCurrency
            applyCost = settings.applyCost
            bankBrokerName = settings.bankBrokerName
            defaultFixedCost = settings.defaultFixedCost
            defaultVariableCost = settings.defaultVariableCost
            defaultMaximumCost = settings.defaultMaximumCost
        } else {
            // Create default settings if none exist
            let newSettings = Settings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }

    private func saveSettings() {
        let settings = settings ?? Settings()
        if settingsQuery.isEmpty {
            modelContext.insert(settings)
        }

        settings.displayMode = displayMode
        settings.doubleCurrency = doubleCurrency
        settings.baseCurrency = baseCurrency
        settings.transactionCurrency = transactionCurrency
        settings.applyCost = applyCost
        settings.bankBrokerName = bankBrokerName
        settings.defaultFixedCost = defaultFixedCost
        settings.defaultVariableCost = defaultVariableCost
        settings.defaultMaximumCost = defaultMaximumCost
        settings.modifiedAt = Date()

        try? modelContext.save()
    }

    private func swapCurrencies() {
        let temp = baseCurrency
        baseCurrency = transactionCurrency
        transactionCurrency = temp
        saveSettings()
    }

    private func loadCostsFromProvider(_ providerName: String) {
        guard !providerName.isEmpty else { return }

        // Find all providers with this name
        let matchingProviders = allProviders.filter {
            $0.bankBrokerName.lowercased() == providerName.lowercased()
        }

        guard !matchingProviders.isEmpty else { return }

        // Get the currently active provider (no end date or end date in the future)
        let now = Date()
        let activeProvider = matchingProviders.first { provider in
            if let endDate = provider.endDate {
                return endDate >= now
            }
            return true // No end date means active
        }

        // If no active provider, use the most recent one (by start date)
        let selectedProvider = activeProvider ?? matchingProviders.sorted { $0.startDate > $1.startDate }.first

        // Load costs from the selected provider
        if let provider = selectedProvider {
            defaultFixedCost = provider.fixedCost
            defaultVariableCost = provider.variableCostRate
            defaultMaximumCost = provider.maximumCost > 0 ? provider.maximumCost : nil
        }
    }

    private func clearCurrentField() {
        switch focusedField {
        case .bankBrokerName:
            bankBrokerName = ""
        case .fixedCost:
            defaultFixedCost = 0
        case .variableCost:
            defaultVariableCost = 0
        case .maximumCost:
            defaultMaximumCost = nil
        default:
            break
        }
        saveSettings()
    }

    private func moveToPreviousField() {
        switch focusedField {
        case .bankBrokerName:
            focusedField = nil
        case .fixedCost:
            focusedField = .bankBrokerName
        case .variableCost:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCost
        default:
            focusedField = nil
        }
    }

    private func moveToNextField() {
        switch focusedField {
        case .bankBrokerName:
            if applyCost {
                focusedField = .fixedCost
            } else {
                focusedField = nil
            }
        case .fixedCost:
            focusedField = .variableCost
        case .variableCost:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil
        default:
            focusedField = .bankBrokerName
        }
    }
}

#Preview {
    SettingsView(tab: .settings)
}
