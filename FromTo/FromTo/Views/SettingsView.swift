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

    // MARK: - let values for keyboard buttons
    let circleFrameSize: CGFloat = 40
    let opacityValue: Double = 0.2
    let hPadding: CGFloat = 10
    let vPadding: CGFloat = 8

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
                Section("Appearance") {
                    Picker("Display Mode", selection: $settings.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Currency Section
                Section {
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
                } header: {
                    HStack {
                        Text("Currency")
                        Spacer()
                        Button(action: {
                            swapCurrencies()
                        }) {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                        }
                        .buttonStyle(.borderedProminent)
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

                // MARK: - Information Section
                Section("Information") {
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
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                            .background(Capsule().fill(.red).opacity(opacityValue))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.teal)
                            .frame(width: circleFrameSize, height: circleFrameSize, alignment: .center)
                            .background(Circle().fill(.teal).opacity(opacityValue))
                    }
                    .disabled(focusedField == .currencyRate || focusedField == nil)
                    
                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                            .frame(width: circleFrameSize, height: circleFrameSize, alignment: .center)
                            .background(Circle().fill(.blue).opacity(opacityValue))
                    }
                    .disabled(focusedField == .maximumCost || focusedField == nil)
                    
                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .foregroundColor(.green)
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                            .background(Capsule().fill(.green).opacity(opacityValue))
                    }
                }
            }
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


}

#Preview {
    SettingsView()
        .environmentObject(SettingsData())
}
