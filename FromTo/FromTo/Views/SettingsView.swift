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
    @Query private var allProviders: [BankBrokerProvider]
    let tab: AppTab

    // Draft state for settings
    @State private var displayMode: DisplayMode = .system
    @State private var doubleCurrency: Bool = true
    @State private var baseCurrency: String = "USD"
    @State private var transactionCurrency: String = "EUR"
    @State private var applyCost: Bool = true
    @State private var defaultProviderId: UUID? = nil
    @State private var showingSameCurrencyAlert = false

    private var settings: Settings? {
        settingsQuery.first
    }

    private var selectedProvider: BankBrokerProvider? {
        guard let providerId = defaultProviderId else { return nil }
        return allProviders.first { $0.id == providerId }
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

                // MARK: - Cost Provider Section
                Section {
                    Toggle("Apply Cost", isOn: $applyCost)
                        .onChange(of: applyCost) { _, newValue in
                            if !newValue {
                                defaultProviderId = nil
                            }
                            saveSettings()
                        }

                    if applyCost {
                        NavigationLink(
                            destination: ProviderCostListView(
                                selectionMode: .single,
                                selectedProviderId: $defaultProviderId,
                                tab: tab
                            )
                        ) {
                            HStack {
                                Text("Default Provider")
                                Spacer()
                                Text(selectedProvider?.displayName ?? "None Selected")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onChange(of: defaultProviderId) { _, _ in saveSettings() }

                        // Show provider summary if one is selected
                        if let provider = selectedProvider {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Cost Components:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(provider.costComponents?.count ?? 0)")
                                        .font(.subheadline)
                                        .bold()
                                }

                                ForEach(provider.costComponents ?? []) { component in
                                    HStack {
                                        Image(systemName: component.isCredit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                            .foregroundColor(component.isCredit ? .green : .blue)
                                            .font(.caption)
                                        Text(component.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(component.calculationMethod.displayName)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        NavigationLink(
                            destination: ProviderCostListView(
                                selectionMode: .manage,
                                selectedProviderId: .constant(nil),
                                tab: tab
                            )
                        ) {
                            Text("Manage All Providers")
                        }
                    }
                } header: {
                    Text("Cost Provider")
                        .foregroundStyle(tab.color())
                } footer: {
                    if applyCost {
                        Text("Select a cost provider to automatically apply fees to new projections")
                    }
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
            .tint(tab.color())
            .onAppear {
                loadSettings()
            }
            .alert("Same Currency Not Allowed", isPresented: $showingSameCurrencyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The Frankfurter API does not support the same currency for both Base Currency and Transaction Currency. The Transaction Currency has been automatically changed to \(transactionCurrency).")
            }
        }
    }

    // MARK: - Helper Methods
    private func loadSettings() {
        if let settings = settings {
            displayMode = settings.displayMode
            doubleCurrency = settings.doubleCurrency
            baseCurrency = settings.baseCurrency
            transactionCurrency = settings.transactionCurrency
            applyCost = settings.applyCost
            defaultProviderId = settings.defaultProviderId
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
        settings.defaultProviderId = defaultProviderId
        settings.modifiedAt = Date()

        try? modelContext.save()
    }

    private func swapCurrencies() {
        let temp = baseCurrency
        baseCurrency = transactionCurrency
        transactionCurrency = temp
        saveSettings()
    }
}

#Preview {
    SettingsView(tab: .settings)
}
