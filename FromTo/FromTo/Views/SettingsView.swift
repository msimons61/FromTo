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
    let tab: AppTab

    // MARK: - let values for keyboard buttons
//    let circleFrameSize: CGFloat = 40
//    let opacityValue: Double = 0.2
//    let hPadding: CGFloat = 10
//    let vPadding: CGFloat = 8

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
                    Picker("Display Mode", selection: $settings.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(tab.color())
                } header: {
                    Text("Appearance")
                        .foregroundStyle(tab.color())
                }

                // MARK: - Currency Section
                Section {
                    Toggle("Double Currency", isOn: $settings.isDoubleCurrencyEnabled)

                    NavigationLink(
                        destination: CurrencySelectionView(
                            selectedCurrency: $settings.fromCurrency,
                            availableCurrencies: settings.availableCurrencies,
                            title: settings.isDoubleCurrencyEnabled ? "From Currency" : "Currency",
                            tab: tab
                        )
                    ) {
                        HStack {
                            Text(settings.isDoubleCurrencyEnabled ? "From Currency" : "Currency")
                            Spacer()
                            Text(settings.fromCurrency)
                                .foregroundColor(.secondary)
                        }
                    }

                    if settings.isDoubleCurrencyEnabled {
                        NavigationLink(
                            destination: CurrencySelectionView(
                                selectedCurrency: $settings.toCurrency,
                                availableCurrencies: settings.availableCurrencies,
                                title: "To Currency",
                                tab: tab
                            )
                        ) {
                            HStack {
                                Text("To Currency")
                                Spacer()
                                Text(settings.toCurrency)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if settings.isDoubleCurrencyEnabled {
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
                                includeGrouping: false,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .currencyRate)
                        }
                    }
                } header: {
                    HStack {
                        Text("Currency")
                            .foregroundStyle(tab.color())
                        Spacer()
                        if settings.isDoubleCurrencyEnabled {
                            Button(action: {
                                swapCurrencies()
                            }) {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .circleBackground(fgColor: tab.color(), font: .body.bold(), size: 5)
                            }
                        }
                    }
                }

                // MARK: - Default Cost Section
                Section {
                    Toggle("Apply Cost", isOn: $settings.isApplyCostEnabled)

                    if settings.isApplyCostEnabled {
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
                                suffix: settings.fromCurrency,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .fixedCost)
                        }

                        HStack {
                            Text("Variable Cost")
                            Spacer()
                            PercentageTextField(
                                label: "Variable",
                                tab: tab,
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
                    .disabled(focusedField == .currencyRate || focusedField == nil)

                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .kbCapsuleBackground(color: .blue)
                    }
                    .disabled(focusedField == .maximumCost || focusedField == nil)

                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .kbCapsuleBackground(color: .green)
                    }
                }
            }
            .tint(tab.color())
        }
    }

    enum Field {
        case currencyRate, fixedCost, variableCost, maximumCost
    }

    // MARK: - Helper Methods
    private func swapCurrencies() {
        let temp = settings.fromCurrency
        settings.fromCurrency = settings.toCurrency
        settings.toCurrency = temp
    }

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
            focusedField = nil  // First field, no previous
        case .fixedCost:
            // Go to currencyRate if Double Currency enabled, else no previous
            focusedField = settings.isDoubleCurrencyEnabled ? .currencyRate : nil
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
            // Go to fixedCost if Apply Cost enabled, else dismiss keyboard
            focusedField = settings.isApplyCostEnabled ? .fixedCost : nil
        case .fixedCost:
            focusedField = .variableCost
        case .variableCost:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil  // Last field, dismiss keyboard
        }
    }
}

#Preview {
    SettingsView(tab: .settings)
        .environmentObject(SettingsData())
}
