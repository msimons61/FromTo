//
//  InvestmentView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct InvestmentView: View {
    @StateObject private var viewModel: InvestmentViewModel
    @EnvironmentObject var settings: SettingsData
    @FocusState private var focusedField: Field?
    let tab: AppTab

    init(settings: SettingsData, tab: AppTab) {
        _viewModel = StateObject(wrappedValue: InvestmentViewModel(settings: settings))
        self.tab = tab
    }

    // MARK: - let values for keyboard buttons
    let circleFrameSize: CGFloat = 40
    let opacityValue: Double = 0.2
    let hPadding: CGFloat = 10
    let vPadding: CGFloat = 8

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Investment Details Section
                Section {
                    HStack {
                        Text("Available Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $viewModel.availableAmount,
                            fractionDigits: 2,
                            suffix: settings.fromCurrency,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .availableAmount)
                    }

                    HStack {
                        Text("Stock Price")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Price",
                            value: $viewModel.stockPrice,
                            fractionDigits: 2,
                            suffix: settings.toCurrency,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .stockPrice)
                    }
                } header: {
                    Text("Investment Details")
                        .foregroundStyle(tab.color())
                }
                
                // MARK: - Costs Section
                // Show section if Double Currency OR Apply Cost is enabled (Scenarios 1, 2, 3)
                // Hide section only when both are disabled (Scenario 4)
                if settings.isDoubleCurrencyEnabled || settings.isApplyCostEnabled {
                    Section {
                        // Currency Rate: Show only when Double Currency is enabled (Scenarios 1, 2)
                        if settings.isDoubleCurrencyEnabled {
                            HStack {
                                Text("Currency Rate")
                                Spacer()
                                DecimalTextFieldNonOptional(
                                    label: "Rate",
                                    value: $viewModel.currencyRate,
                                    fractionDigits: 6,
                                    includeGrouping: false,
                                    tab: tab
                                )
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .currencyRate)
                            }
                        }

                        // Cost fields: Show only when Apply Cost is enabled (Scenarios 1, 3)
                        if settings.isApplyCostEnabled {
                            HStack {
                                Text("Fixed Cost")
                                Spacer()
                                DecimalTextFieldNonOptional(
                                    label: "Fixed",
                                    value: $viewModel.fixedCost,
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
                                    value: $viewModel.variableCost
                                )
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .variableCost)
                            }

                            HStack {
                                Text("Maximum Cost")
                                Spacer()
                                DecimalTextField(
                                    label: "Maximum",
                                    value: $viewModel.maximumCost,
                                    fractionDigits: 2,
                                    suffix: settings.fromCurrency
                                )
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .maximumCost)
                            }

                            HStack {
                                Text("Total Cost")
                                Spacer()
                                Text(viewModel.totalCost.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.fromCurrency)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Costs")
                                .foregroundStyle(tab.color())
                            Spacer()
                            // Reload button: Show in all scenarios except Scenario 4
                            Button(action: {
                                viewModel.reloadCostsFromSettings()
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                            }
                            .circleBackground(fgColor: tab.color(), font: .body.bold(), size: 5)
                        }
                    }
                }

                // MARK: - Results Section
                Section {
                    HStack {
                        Text("Investable Amount")
                        Spacer()
                        Text(viewModel.investableAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Number of Stocks")
                        Spacer()
                        Text("\(viewModel.numberOfStocks)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Invested Amount")
                        Spacer()
                        Text(viewModel.investedAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Remaining Amount")
                        Spacer()
                        Text(viewModel.remainingAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Results")
                        .foregroundStyle(tab.color())
                }
            }
            .navigationTitle("Investment")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        clearCurrentField()
                    }) {
                        Text("Clear")
                        .kbCapsuleBackground(color: .red)                    }

                    Spacer()

                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                        .kbCapsuleBackground(color: .teal)                    }
                    .disabled(focusedField == .availableAmount || focusedField == nil)

                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                        .kbCapsuleBackground(color: .blue)                    }
                    .disabled(focusedField == .maximumCost || focusedField == nil)

                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                        .kbCapsuleBackground(color: .green)                    }
                }
            }
            .tint(tab.color())
        }
    }

    enum Field {
        case availableAmount, stockPrice, currencyRate, fixedCost, variableCost, maximumCost
    }

    // MARK: - Helper Methods
    private func clearCurrentField() {
        guard let field = focusedField else { return }

        switch field {
        case .availableAmount:
            viewModel.availableAmount = 0
        case .stockPrice:
            viewModel.stockPrice = 0
        case .currencyRate:
            viewModel.currencyRate = 1.0
        case .fixedCost:
            viewModel.fixedCost = 0
        case .variableCost:
            viewModel.variableCost = 0
        case .maximumCost:
            viewModel.maximumCost = nil
        }
    }

    private func moveToPreviousField() {
        guard let current = focusedField else { return }

        switch current {
        case .availableAmount:
            focusedField = nil  // First field, no previous
        case .stockPrice:
            focusedField = .availableAmount
        case .currencyRate:
            focusedField = .stockPrice
        case .fixedCost:
            // Go to currencyRate if Double Currency enabled, else go to stockPrice
            focusedField = settings.isDoubleCurrencyEnabled ? .currencyRate : .stockPrice
        case .variableCost:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCost
        }
    }

    private func moveToNextField() {
        guard let current = focusedField else { return }

        switch current {
        case .availableAmount:
            focusedField = .stockPrice
        case .stockPrice:
            // Navigate based on what's visible in Costs section
            if settings.isDoubleCurrencyEnabled {
                // Double Currency is ON, go to Currency Rate
                focusedField = .currencyRate
            } else if settings.isApplyCostEnabled {
                // Double Currency is OFF but Apply Cost is ON, go to Fixed Cost
                focusedField = .fixedCost
            } else {
                // Both are OFF (Scenario 4), Costs section is hidden, dismiss keyboard
                focusedField = nil
            }
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
    InvestmentView(settings: SettingsData(), tab: .investment)
        .environmentObject(SettingsData())
}
