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

    // MARK: - Filtered Currency Lists
    /// Available base currencies (excludes transaction currency when double currency is enabled)
    private var availableBaseCurrencies: [String] {
        let currencies = settings?.availableCurrencies ?? []
        guard settings?.doubleCurrency == true else { return currencies }
        return currencies.filter { $0 != transactionCurrency }
    }

    /// Available transaction currencies (always excludes base currency)
    private var availableTransactionCurrencies: [String] {
        let currencies = settings?.availableCurrencies ?? []
        return currencies.filter { $0 != baseCurrency }
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
    @State private var transactionType: TransactionType

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false
    @State private var isFetchingRate = false

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
        _transactionType = State(initialValue: investment.transactionType)
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
                Picker("Transaction Type", selection: $transactionType) {
                    ForEach(TransactionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .onChange(of: transactionType) { _, _ in hasChanges = true }
                

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
                    .onChange(of: transactionDate) { _, _ in
                        hasChanges = true
                        fetchCurrencyRate()
                    }

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
            if transactionType != .deposit && transactionType != .withdrawal {
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
            }

            // MARK: - Currency Section
            Section {
                NavigationLink(
                    destination: CurrencySelectionView(
                        selectedCurrency: $baseCurrency,
                        availableCurrencies: availableBaseCurrencies,
                        title: settings?.doubleCurrency == true ? "Base Currency" : "Currency",
                        tab: tab
                    )
                ) {
                    HStack {
                        Text(settings?.doubleCurrency == true ? "Base Currency" : "Currency")
                        Spacer()
                        Text(baseCurrency)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: baseCurrency) { _, _ in
                    hasChanges = true
                    fetchCurrencyRate()
                }

                if settings?.doubleCurrency == true {
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
                    .onChange(of: transactionCurrency) { _, _ in
                        hasChanges = true
                        fetchCurrencyRate()
                    }

                    HStack {
                        Text("Currency Rate")
                        Spacer()
                        if isFetchingRate {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
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

                        Button(action: {
                            fetchCurrencyRate()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .circleBackground(fgColor: tab.color(), font: .body.bold(), padding: 5)
                        .disabled(isFetchingRate)
                    }
                }
            } header: {
                Text("Currency")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Costs Section
            if transactionType != .deposit && transactionType != .withdrawal {
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
                        .circleBackground(fgColor: tab.color(), font: .body.bold(), padding: 5)
                    }
                }
            }

            // MARK: - Results Section
            if transactionType != .deposit && transactionType != .withdrawal {
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
        case name, ticker, numberOfStocks, stockPrice, currencyRate, fixedCost, variableCost, maximumCost, bankBrokerName
    }

    // MARK: - Helper Methods
    private func saveChanges() {
        // Copy draft values back to the model
        investment.name = name.isEmpty ? nil : name
        investment.ticker = ticker
        investment.transactionDate = transactionDate
        investment.transactionType = transactionType
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

        // Update associated Balance record
        if let balance = investment.balance {
            balance.transactionDate = transactionDate
            balance.transactionType = transactionType
            balance.bankBrokerName = bankBrokerName
            balance.ticker = ticker
            balance.name = name.isEmpty ? nil : name
            balance.numberOfStocks = numberOfStocksInt
            balance.stockPrice = stockPrice
            balance.transactionCost = investment.totalCost
            balance.modifiedAt = Date()
        } else {
            // Create Balance if it doesn't exist
            let newBalance = Balance.from(investment)
            modelContext.insert(newBalance)
            investment.balance = newBalance
        }

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

    private func fetchCurrencyRate() {
        // Only fetch if double currency is enabled and currencies are different
        guard settings?.doubleCurrency == true else { return }
        guard baseCurrency != transactionCurrency else {
            currencyRate = 1.0
            return
        }

        isFetchingRate = true

        Task {
            do {
                let rate = try await CurrencyRateService.shared.fetchRate(
                    from: baseCurrency,
                    to: transactionCurrency,
                    on: transactionDate
                )
                await MainActor.run {
                    currencyRate = rate
                    hasChanges = true
                    isFetchingRate = false
                }
            } catch {
                await MainActor.run {
                    isFetchingRate = false
                }
                print("Failed to fetch currency rate: \(error.localizedDescription)")
            }
        }
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
        case .currencyRate:
            focusedField = .stockPrice
        case .bankBrokerName:
            if settings?.doubleCurrency == true {
                focusedField = .currencyRate
            } else {
                focusedField = .stockPrice
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
            if settings?.doubleCurrency == true {
                focusedField = .currencyRate
            } else {
                focusedField = .bankBrokerName
            }
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
