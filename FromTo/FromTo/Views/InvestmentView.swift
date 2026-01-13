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

    init(settings: SettingsData) {
        _viewModel = StateObject(wrappedValue: InvestmentViewModel(settings: settings))
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
                        Text(viewModel.totalCost.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.fromCurrency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    HStack {
                        Text("Costs")
                        Spacer()
                        Button(action: {
                            viewModel.reloadCostsFromSettings()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // MARK: - Results Section
                Section("Results") {
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
                    .disabled(focusedField == .availableAmount || focusedField == nil)
                    
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


}

#Preview {
    InvestmentView(settings: SettingsData())
        .environmentObject(SettingsData())
}
