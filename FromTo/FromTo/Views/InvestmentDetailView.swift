//
//  InvestmentDetailView.swift
//  FromTo
//
//  Created by Claude Code on 14-01-2026.
//

import SwiftUI
import SwiftData

struct InvestmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: SettingsData

    let investment: Investment
    let tab: AppTab

    // Draft copies for editing
    @State private var name: String
    @State private var transactionDate: Date
    @State private var availableAmount: Decimal
    @State private var stockPrice: Decimal
    @State private var currencyRate: Decimal
    @State private var fixedCost: Decimal
    @State private var variableCost: Decimal
    @State private var maximumCost: Decimal?

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false

    init(investment: Investment, tab: AppTab) {
        self.investment = investment
        self.tab = tab

        // Initialize draft state from investment model
        _name = State(initialValue: investment.name ?? "")
        _transactionDate = State(initialValue: investment.transactionDate)
        _availableAmount = State(initialValue: investment.availableAmount)
        _stockPrice = State(initialValue: investment.stockPrice)
        _currencyRate = State(initialValue: investment.currencyRate)
        _fixedCost = State(initialValue: investment.fixedCost)
        _variableCost = State(initialValue: investment.variableCost)
        _maximumCost = State(initialValue: investment.maximumCost)
    }

    // MARK: - Computed Properties (mirror Investment model)
    private var totalCost: Decimal {
        let variableCostAmount = availableAmount * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        if let maxCost = maximumCost, maxCost > 0 {
            return min(totalWithoutMax, maxCost)
        }
        return totalWithoutMax
    }

    private var investableAmount: Decimal {
        let netAmount = availableAmount - totalCost
        return currencyRate != 0 ? netAmount / currencyRate : 0
    }

    private var numberOfStocks: Int {
        guard stockPrice > 0 else { return 0 }

        let stocks = investableAmount / stockPrice

        var stocksValue = stocks
        var rounded = Decimal()
        NSDecimalRound(&rounded, &stocksValue, 0, .down)

        return Int(truncating: rounded as NSNumber)
    }

    private var investedAmount: Decimal {
        return Decimal(numberOfStocks) * stockPrice
    }

    private var remainingAmount: Decimal {
        return investableAmount - investedAmount
    }

    var body: some View {
        Form {
            // MARK: - Details Section
            Section {
                TextField("Name (optional)", text: $name)
                    .onChange(of: name) { _, _ in hasChanges = true }

                DatePicker("Transaction Date", selection: $transactionDate, displayedComponents: .date)
                    .onChange(of: transactionDate) { _, _ in hasChanges = true }
            } header: {
                Text("Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Investment Details Section
            Section {
                HStack {
                    Text("Available Amount")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Amount",
                        value: $availableAmount,
                        fractionDigits: 2,
                        suffix: settings.fromCurrency,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .availableAmount)
                    .onChange(of: availableAmount) { _, _ in hasChanges = true }
                }

                HStack {
                    Text("Stock Price")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Price",
                        value: $stockPrice,
                        fractionDigits: 2,
                        suffix: settings.toCurrency,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .stockPrice)
                    .onChange(of: stockPrice) { _, _ in hasChanges = true }
                }
            } header: {
                Text("Investment Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Costs Section
            if settings.isDoubleCurrencyEnabled || settings.isApplyCostEnabled {
                Section {
                    // Currency Rate: Show only when Double Currency is enabled
                    if settings.isDoubleCurrencyEnabled {
                        HStack {
                            Text("Currency Rate")
                            Spacer()
                            DecimalTextFieldNonOptional(
                                label: "Rate",
                                value: $currencyRate,
                                fractionDigits: 6,
                                includeGrouping: false,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .currencyRate)
                            .onChange(of: currencyRate) { _, _ in hasChanges = true }
                        }
                    }

                    // Cost fields: Show only when Apply Cost is enabled
                    if settings.isApplyCostEnabled {
                        HStack {
                            Text("Fixed Cost")
                            Spacer()
                            DecimalTextFieldNonOptional(
                                label: "Fixed",
                                value: $fixedCost,
                                fractionDigits: 2,
                                suffix: settings.fromCurrency,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .fixedCost)
                            .onChange(of: fixedCost) { _, _ in hasChanges = true }
                        }

                        HStack {
                            Text("Variable Cost")
                            Spacer()
                            PercentageTextField(
                                label: "Variable",
                                tab: tab,
                                value: $variableCost
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .variableCost)
                            .onChange(of: variableCost) { _, _ in hasChanges = true }
                        }

                        HStack {
                            Text("Maximum Cost")
                            Spacer()
                            DecimalTextField(
                                label: "Maximum",
                                value: $maximumCost,
                                fractionDigits: 2,
                                suffix: settings.fromCurrency
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .maximumCost)
                            .onChange(of: maximumCost) { _, _ in hasChanges = true }
                        }

                        HStack {
                            Text("Total Cost")
                            Spacer()
                            Text(totalCost.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.fromCurrency)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    HStack {
                        Text("Costs")
                            .foregroundStyle(tab.color())
                        Spacer()
                        // Reload button to load costs from settings
                        Button(action: {
                            reloadCostsFromSettings()
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
                    Text(investableAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Number of Stocks")
                    Spacer()
                    Text("\(numberOfStocks)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Invested Amount")
                    Spacer()
                    Text(investedAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Remaining Amount")
                    Spacer()
                    Text(remainingAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + settings.toCurrency)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Results")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Information Section
            Section {
                HStack {
                    Text("Created At")
                    Spacer()
                    Text(investment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Modified At")
                    Spacer()
                    Text(investment.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Information")
                    .foregroundStyle(tab.color())
            }
        }
        .navigationTitle("Investment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!hasChanges)
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            // Keyboard toolbar
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
                .disabled(focusedField == .availableAmount || focusedField == nil)

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

    enum Field {
        case availableAmount, stockPrice, currencyRate, fixedCost, variableCost, maximumCost
    }

    // MARK: - Helper Methods
    private func saveChanges() {
        // Copy draft values back to the model
        investment.name = name.isEmpty ? nil : name
        investment.transactionDate = transactionDate
        investment.availableAmount = availableAmount
        investment.stockPrice = stockPrice
        investment.currencyRate = currencyRate
        investment.fixedCost = fixedCost
        investment.variableCost = variableCost
        investment.maximumCost = maximumCost
        investment.modifiedAt = Date()

        try? modelContext.save()
        hasChanges = false
        dismiss()
    }

    private func reloadCostsFromSettings() {
        currencyRate = settings.currencyRate
        fixedCost = settings.defaultFixedCost
        variableCost = settings.defaultVariableCost
        maximumCost = settings.defaultMaximumCost
        hasChanges = true
    }

    private func clearCurrentField() {
        guard let field = focusedField else { return }

        switch field {
        case .availableAmount:
            availableAmount = 0
        case .stockPrice:
            stockPrice = 0
        case .currencyRate:
            currencyRate = 1.0
        case .fixedCost:
            fixedCost = 0
        case .variableCost:
            variableCost = 0
        case .maximumCost:
            maximumCost = nil
        }
        hasChanges = true
    }

    private func moveToPreviousField() {
        guard let current = focusedField else { return }

        switch current {
        case .availableAmount:
            focusedField = nil
        case .stockPrice:
            focusedField = .availableAmount
        case .currencyRate:
            focusedField = .stockPrice
        case .fixedCost:
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
            if settings.isDoubleCurrencyEnabled {
                focusedField = .currencyRate
            } else if settings.isApplyCostEnabled {
                focusedField = .fixedCost
            } else {
                focusedField = nil
            }
        case .currencyRate:
            focusedField = settings.isApplyCostEnabled ? .fixedCost : nil
        case .fixedCost:
            focusedField = .variableCost
        case .variableCost:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil
        }
    }
}

#Preview {
    NavigationStack {
        InvestmentDetailView(
            investment: Investment(
                availableAmount: 1000,
                stockPrice: 50,
                currencyRate: 1.2,
                fixedCost: 10,
                variableCost: 0.01,
                name: "Test Investment"
            ),
            tab: .investment
        )
        .environmentObject(SettingsData())
    }
}
