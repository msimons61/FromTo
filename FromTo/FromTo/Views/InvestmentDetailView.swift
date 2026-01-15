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
    @Query private var settingsQuery: [Settings]

    let investment: Investment
    let tab: AppTab

    private var settings: Settings? {
        settingsQuery.first
    }

    // Draft copies for editing
    @State private var name: String
    @State private var ticker: String
    @State private var transactionDate: Date
    @State private var numberOfStocks: String
    @State private var stockPrice: Decimal
    @State private var baseCurrency: String
    @State private var transactionCurrency: String
    @State private var currencyRate: Decimal
    @State private var fixedCost: Decimal
    @State private var variableCost: Decimal
    @State private var maximumCost: Decimal
    @State private var bankBrokerName: String
    @State private var providerName: String

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false

    init(investment: Investment, tab: AppTab) {
        self.investment = investment
        self.tab = tab

        // Initialize draft state from investment model
        _name = State(initialValue: investment.name ?? "")
        _ticker = State(initialValue: investment.ticker)
        _transactionDate = State(initialValue: investment.transactionDate)
        _numberOfStocks = State(initialValue: String(investment.numberOfStocks))
        _stockPrice = State(initialValue: investment.stockPrice)
        _baseCurrency = State(initialValue: investment.baseCurrency)
        _transactionCurrency = State(initialValue: investment.transactionCurrency)
        _currencyRate = State(initialValue: investment.currencyRate)
        _fixedCost = State(initialValue: investment.fixedCost)
        _variableCost = State(initialValue: investment.variableCost)
        _maximumCost = State(initialValue: investment.maximumCost)
        _bankBrokerName = State(initialValue: investment.bankBrokerName)
        _providerName = State(initialValue: investment.providerName ?? "")
    }

    // MARK: - Computed Properties
    private var numberOfStocksInt: Int {
        return Int(numberOfStocks) ?? 0
    }

    private var totalInvested: Decimal {
        return Decimal(numberOfStocksInt) * stockPrice
    }

    private var totalCost: Decimal {
        // Variable cost applies to the invested amount in base currency
        let investedAmountBase = totalInvested / currencyRate
        let variableCostAmount = investedAmountBase * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        // Apply minimum cost of 150
        let costWithMinimum = max(150, totalWithoutMax)

        // Apply maximum cost cap
        if maximumCost > 0 {
            return min(costWithMinimum, maximumCost)
        }
        return costWithMinimum
    }

    private var totalAmount: Decimal {
        return totalInvested + totalCost
    }

    private var totalAmountInBaseCurrency: Decimal {
        return totalAmount / currencyRate
    }

    var body: some View {
        Form {
            // MARK: - Details Section
            Section {
                HStack {
                    TextField("Name (optional)", text: $name)
                        .focused($focusedField, equals: .name)
                        .onChange(of: name) { _, _ in hasChanges = true }

                    if !name.isEmpty {
                        Button(action: {
                            name = ""
                            hasChanges = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                HStack {
                    TextField("Ticker Symbol", text: $ticker)
                        .textInputAutocapitalization(.characters)
                        .focused($focusedField, equals: .ticker)
                        .onChange(of: ticker) { _, _ in hasChanges = true }

                    if !ticker.isEmpty {
                        Button(action: {
                            ticker = ""
                            hasChanges = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                DatePicker("Transaction Date", selection: $transactionDate, displayedComponents: .date)
                    .onChange(of: transactionDate) { _, _ in hasChanges = true }

                HStack {
                    TextField("Bank/Broker Name", text: $bankBrokerName)
                        .focused($focusedField, equals: .bankBrokerName)
                        .onChange(of: bankBrokerName) { _, _ in hasChanges = true }
                }

                if !providerName.isEmpty {
                    HStack {
                        Text("Provider")
                        Spacer()
                        Text(providerName)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Investment Details Section
            Section {
                HStack {
                    Text("Number of Stocks")
                    Spacer()
                    TextField("0", text: $numberOfStocks)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .numberOfStocks)
                        .onChange(of: numberOfStocks) { _, _ in hasChanges = true }
                }

                HStack {
                    Text("Stock Price")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Price",
                        value: $stockPrice,
                        fractionDigits: 2,
                        suffix: transactionCurrency,
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

            // MARK: - Currency Section
            Section {
                HStack {
                    Text(settings?.doubleCurrency == true ? "Base Currency" : "Currency")
                    Spacer()
                    TextField("USD", text: $baseCurrency)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.characters)
                        .focused($focusedField, equals: .baseCurrency)
                        .onChange(of: baseCurrency) { _, _ in hasChanges = true }
                }

                if settings?.doubleCurrency == true {
                    HStack {
                        Text("Transaction Currency")
                        Spacer()
                        TextField("EUR", text: $transactionCurrency)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                            .focused($focusedField, equals: .transactionCurrency)
                            .onChange(of: transactionCurrency) { _, _ in hasChanges = true }
                    }

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
            } header: {
                Text("Currency")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Costs Section
            Section {
                HStack {
                    Text("Fixed Cost")
                    Spacer()
                    DecimalTextFieldNonOptional(
                        label: "Fixed",
                        value: $fixedCost,
                        fractionDigits: 2,
                        suffix: baseCurrency,
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
                    DecimalTextFieldNonOptional(
                        label: "Maximum",
                        value: $maximumCost,
                        fractionDigits: 2,
                        suffix: baseCurrency,
                        tab: tab
                    )
                    .multilineTextAlignment(.trailing)
                    .focused($focusedField, equals: .maximumCost)
                    .onChange(of: maximumCost) { _, _ in hasChanges = true }
                }

                HStack {
                    Text("Total Cost")
                    Spacer()
                    Text(totalCost.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + baseCurrency)
                        .foregroundColor(.secondary)
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

            // MARK: - Results Section
            Section {
                HStack {
                    Text("Total Invested")
                    Spacer()
                    Text(totalInvested.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Total Amount")
                    Spacer()
                    Text(totalAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                        .foregroundColor(.secondary)
                }

                if settings?.doubleCurrency == true {
                    HStack {
                        Text("Amount in \(baseCurrency)")
                        Spacer()
                        Text(totalAmountInBaseCurrency.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + baseCurrency)
                            .foregroundColor(.secondary)
                    }
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
                .disabled(focusedField == .name || focusedField == nil)

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

    enum Field: Hashable {
        case name, ticker, numberOfStocks, stockPrice, baseCurrency, transactionCurrency, currencyRate, fixedCost, variableCost, maximumCost, bankBrokerName
    }

    // MARK: - Helper Methods
    private func saveChanges() {
        // Copy draft values back to the model
        investment.name = name.isEmpty ? nil : name
        investment.ticker = ticker
        investment.transactionDate = transactionDate
        investment.numberOfStocks = numberOfStocksInt
        investment.stockPrice = stockPrice
        investment.baseCurrency = baseCurrency
        investment.transactionCurrency = transactionCurrency
        investment.currencyRate = currencyRate
        investment.fixedCost = fixedCost
        investment.variableCost = variableCost
        investment.maximumCost = maximumCost
        investment.bankBrokerName = bankBrokerName
        investment.providerName = providerName.isEmpty ? nil : providerName
        investment.modifiedAt = Date()

        try? modelContext.save()
        hasChanges = false
        dismiss()
    }

    private func reloadCostsFromSettings() {
        guard let settings = settings else { return }
        fixedCost = settings.defaultFixedCost
        variableCost = settings.defaultVariableCost
        maximumCost = settings.defaultMaximumCost ?? 0
        hasChanges = true
    }

    private func clearCurrentField() {
        guard let field = focusedField else { return }

        switch field {
        case .name:
            name = ""
        case .ticker:
            ticker = ""
        case .numberOfStocks:
            numberOfStocks = "0"
        case .stockPrice:
            stockPrice = 0
        case .baseCurrency:
            baseCurrency = ""
        case .transactionCurrency:
            transactionCurrency = ""
        case .currencyRate:
            currencyRate = 1.0
        case .fixedCost:
            fixedCost = 0
        case .variableCost:
            variableCost = 0
        case .maximumCost:
            maximumCost = 0
        case .bankBrokerName:
            bankBrokerName = ""
        }
        hasChanges = true
    }

    private func moveToPreviousField() {
        guard let current = focusedField else { return }

        switch current {
        case .name:
            focusedField = nil
        case .ticker:
            focusedField = .name
        case .numberOfStocks:
            focusedField = .ticker
        case .stockPrice:
            focusedField = .numberOfStocks
        case .baseCurrency:
            focusedField = .stockPrice
        case .transactionCurrency:
            focusedField = .baseCurrency
        case .currencyRate:
            focusedField = .transactionCurrency
        case .bankBrokerName:
            if settings?.doubleCurrency == true {
                focusedField = .currencyRate
            } else {
                focusedField = .baseCurrency
            }
        case .fixedCost:
            focusedField = .bankBrokerName
        case .variableCost:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCost
        }
    }

    private func moveToNextField() {
        guard let current = focusedField else { return }

        switch current {
        case .name:
            focusedField = .ticker
        case .ticker:
            focusedField = .numberOfStocks
        case .numberOfStocks:
            focusedField = .stockPrice
        case .stockPrice:
            focusedField = .baseCurrency
        case .baseCurrency:
            if settings?.doubleCurrency == true {
                focusedField = .transactionCurrency
            } else {
                focusedField = .bankBrokerName
            }
        case .transactionCurrency:
            focusedField = .currencyRate
        case .currencyRate:
            focusedField = .bankBrokerName
        case .bankBrokerName:
            focusedField = .fixedCost
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
                numberOfStocks: 100,
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
