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
    @Query private var allProviders: [BankBrokerProvider]

    let investment: Investment
    let tab: AppTab

    private var settings: Settings? {
        settingsQuery.first
    }

    private var activeProviders: [BankBrokerProvider] {
        allProviders.filter { $0.isActive(on: transactionDate) }
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
    @State private var providerId: UUID?
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
        _providerId = State(initialValue: investment.providerId)
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
        return investment.totalCost
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
                // Bank/Broker selection (always visible)
                if settings?.applyCost == true && !activeProviders.isEmpty {
                    NavigationLink(destination: ProviderCostListView(
                        selectionMode: .single,
                        selectedProviderId: $providerId,
                        tab: tab
                    )) {
                        HStack {
                            Text("Bank/Broker")
                            Spacer()
                            Text(providerName.isEmpty ? "None Selected" : providerName)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: providerId) { _, newValue in
                        if let newId = newValue,
                           let provider = activeProviders.first(where: { $0.id == newId }) {
                            providerName = provider.displayName
                        }
                        hasChanges = true
                    }
                } else if settings?.applyCost == true {
                    HStack {
                        Text("Bank/Broker")
                        Spacer()
                        Text("No active providers")
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Text("Bank/Broker")
                        Spacer()
                        Text("Cost calculation disabled")
                            .foregroundColor(.secondary)
                    }
                }

                if providerId != nil {
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
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
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
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }
                    }

                    DatePicker("Transaction Date", selection: $transactionDate, displayedComponents: .date)
                        .onChange(of: transactionDate) { _, _ in
                            hasChanges = true
                            fetchCurrencyRate()
                        }
                }

            } header: {
                Text("Details")
                    .foregroundStyle(tab.color())
            } footer: {
                if settings?.applyCost == true && activeProviders.isEmpty {
                    Text("Create a provider in Settings to calculate costs")
                        .font(.caption)
                }
            }

            if providerId != nil {
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

                        if !numberOfStocks.isEmpty && numberOfStocks != "0" {
                            Button(action: {
                                numberOfStocks = "0"
                                hasChanges = true
                            }) {
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }
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

                        if stockPrice != 0 {
                            Button(action: {
                                stockPrice = 0
                                hasChanges = true
                            }) {
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }
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

                        if currencyRate != 1.0 {
                            Button(action: {
                                currencyRate = 1.0
                                hasChanges = true
                            }) {
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }

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
                        Text("Total Cost")
                        Spacer()
                        Text(totalCost.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + baseCurrency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Costs")
                        .foregroundStyle(tab.color())
                } footer: {
                    Text("Cost is calculated from the provider at transaction time")
                        .font(.caption)
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
        }
        .navigationTitle("Investment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    saveChanges()
                }) {
                    Image(systemName: "checkmark")
                        .circleBackground(fgColor: tab.color(), font: .body, padding: 6, prominent: hasChanges)
                }
            }

            // Keyboard toolbar
            ToolbarItemGroup(placement: .keyboard) {
                KeyboardToolbarButton.button(.clear) { clearCurrentField() }

                Spacer()

                KeyboardToolbarButton.button(.previous) { moveToPreviousField() }
                    .disabled(focusedField == .name || focusedField == nil)

                KeyboardToolbarButton.button(.next) { moveToNextField() }
                    .disabled(focusedField == .currencyRate || focusedField == nil)

                KeyboardToolbarButton.button(.done(tab.color())) { focusedField = nil }
            }
        }
        .tint(tab.color())
    }

    enum Field: Hashable {
        case name, ticker, numberOfStocks, stockPrice, currencyRate
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
        investment.providerId = providerId
        investment.providerName = providerName.isEmpty ? nil : providerName
        investment.modifiedAt = Date()

        // Update associated Balance record
        if let balance = investment.balance {
            balance.transactionDate = transactionDate
            balance.transactionType = transactionType
            balance.bankBrokerName = investment.providerName ?? ""
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
                focusedField = nil
            }
        case .currencyRate:
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
                name: "Test Investment"
            ),
            tab: .investment
        )
        .environmentObject(SettingsData())
    }
}
