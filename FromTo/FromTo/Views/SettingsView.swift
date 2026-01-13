//
//  SettingsView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsData
    @FocusState private var focusedField: Field?

    enum Field {
        case currencyRate, fixedCost, variableCost, maximumCost
    }

    // MARK: - Helper Methods
    private func clearCurrentField() {
        guard let field = focusedField else { return }

        switch field {
        case .currencyRate:
            settings.currencyRate = 1.0
        case .fixedCost:
            settings.defaultFixedCost = 0
        case .variableCost:
            settings.defaultVariableCost = 0
        case .maximumCost:
            settings.defaultMaximumCost = nil
        }
    }

    private func moveToPreviousField() {
        guard let current = focusedField else { return }

        switch current {
        case .currencyRate:
            focusedField = nil // First field, no previous
        case .fixedCost:
            focusedField = .currencyRate
        case .variableCost:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCost
        }
    }

    private func moveToNextField() {
        guard let current = focusedField else { return }

        switch current {
        case .currencyRate:
            focusedField = .fixedCost
        case .fixedCost:
            focusedField = .variableCost
        case .variableCost:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil // Last field, dismiss keyboard
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Appearance Section
                Section("Appearance") {
                    Picker("Display Mode", selection: $settings.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - Currency Section
                Section("Currency") {
                    NavigationLink(destination: CurrencySelectionView(
                        selectedCurrency: $settings.fromCurrency,
                        availableCurrencies: settings.availableCurrencies,
                        title: "From Currency"
                    )) {
                        HStack {
                            Text("From Currency")
                            Spacer()
                            Text(settings.fromCurrency)
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink(destination: CurrencySelectionView(
                        selectedCurrency: $settings.toCurrency,
                        availableCurrencies: settings.availableCurrencies,
                        title: "To Currency"
                    )) {
                        HStack {
                            Text("To Currency")
                            Spacer()
                            Text(settings.toCurrency)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Currency Rate")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Rate",
                            value: Binding(
                                get: { settings.currencyRate },
                                set: { settings.currencyRate = $0 }
                            ),
                            fractionDigits: 6,
                            includeGrouping: false
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .currencyRate)
                    }
                }

                // MARK: - Default Cost Section
                Section("Default Cost") {
                    HStack {
                        Text("Fixed Cost")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Fixed",
                            value: Binding(
                                get: { settings.defaultFixedCost },
                                set: { settings.defaultFixedCost = $0 }
                            ),
                            fractionDigits: 2,
                            suffix: settings.fromCurrency
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .fixedCost)
                    }

                    HStack {
                        Text("Variable Cost")
                        Spacer()
                        PercentageTextField(
                            label: "Variable",
                            value: Binding(
                                get: { settings.defaultVariableCost },
                                set: { settings.defaultVariableCost = $0 }
                            )
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .variableCost)
                    }

                    HStack {
                        Text("Maximum Cost")
                        Spacer()
                        DecimalTextField(
                            label: "Maximum",
                            value: Binding(
                                get: { settings.defaultMaximumCost },
                                set: { settings.defaultMaximumCost = $0 }
                            ),
                            fractionDigits: 2,
                            suffix: settings.fromCurrency
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .maximumCost)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        clearCurrentField()
                    }) {
                        Text("Clear")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.teal)
                    }
                    .disabled(focusedField == .currencyRate || focusedField == nil)

                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .disabled(focusedField == .maximumCost || focusedField == nil)

                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsData())
}
