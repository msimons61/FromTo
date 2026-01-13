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

    enum Field {
        case availableAmount, stockPrice, currencyRate, fixedCost, variableCost, maximumCost
    }

    init(settings: SettingsData) {
        _viewModel = StateObject(wrappedValue: InvestmentViewModel(settings: settings))
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
            focusedField = nil // First field, no previous
        case .stockPrice:
            focusedField = .availableAmount
        case .currencyRate:
            focusedField = .stockPrice
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
        case .availableAmount:
            focusedField = .stockPrice
        case .stockPrice:
            focusedField = .currencyRate
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
                // MARK: - Investment Details Section
                Section("Investment Details") {
                    HStack {
                        Text("Available Amount")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $viewModel.availableAmount,
                            fractionDigits: 2,
                            suffix: settings.fromCurrency
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
                            suffix: settings.toCurrency
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .stockPrice)
                    }
                }

                // MARK: - Costs Section
                Section {
                    HStack {
                        Text("Currency Rate")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Rate",
                            value: $viewModel.currencyRate,
                            fractionDigits: 6,
                            includeGrouping: false
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .currencyRate)
                    }

                    HStack {
                        Text("Fixed Cost")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Fixed",
                            value: $viewModel.fixedCost,
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
                        Text(viewModel.totalCost.formatted(fractionDigits: 2) + " " + settings.fromCurrency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    HStack {
                        Text("Costs")
                        Spacer()
                        Button(action: {
                            viewModel.reloadCostsFromSettings()
                        }) {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Results Section
                Section("Results") {
                    HStack {
                        Text("Investable Amount")
                        Spacer()
                        Text(viewModel.investableAmount.formatted(fractionDigits: 2) + " " + settings.toCurrency)
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
                        Text(viewModel.investedAmount.formatted(fractionDigits: 2) + " " + settings.toCurrency)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Investment")
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
                    .disabled(focusedField == .availableAmount || focusedField == nil)

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
    InvestmentView(settings: SettingsData())
        .environmentObject(SettingsData())
}
