//
//  ProjectionDetailView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftData
import SwiftUI

struct ProjectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [Settings]
    @Query private var allProviders: [BankBrokerProvider]

    let projection: Projection
    let tab: AppTab

    // Draft copies for editing
    @State private var name: String
    @State private var ticker: String
    @State private var transactionDate: Date
    @State private var baseAmountAvailable: Decimal
    @State private var stockPrice: Decimal
    @State private var actualNumberOfStocks: Int
    @State private var baseCurrency: String
    @State private var transactionCurrency: String
    @State private var currencyRate: Decimal
    @State private var providerId: UUID?
    @State private var providerName: String?
    @State private var transactionType: TransactionType

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false
    @State private var isFetchingRate = false

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
        guard settings?.doubleCurrency ?? true else { return currencies }
        return currencies.filter { $0 != transactionCurrency }
    }

    /// Available transaction currencies (always excludes base currency)
    private var availableTransactionCurrencies: [String] {
        let currencies = settings?.availableCurrencies ?? []
        return currencies.filter { $0 != baseCurrency }
    }

    init(projection: Projection, tab: AppTab) {
        self.projection = projection
        self.tab = tab

        // Initialize draft state from projection model
        _name = State(initialValue: projection.name ?? "")
        _ticker = State(initialValue: projection.ticker)
        _transactionDate = State(initialValue: projection.transactionDate)
        _baseAmountAvailable = State(initialValue: projection.baseAmountAvailable)
        _stockPrice = State(initialValue: projection.stockPrice)
        _actualNumberOfStocks = State(initialValue: projection.actualNumberOfStocks)
        _baseCurrency = State(initialValue: projection.baseCurrency)
        _transactionCurrency = State(initialValue: projection.transactionCurrency)
        _currencyRate = State(initialValue: projection.currencyRate)
        _providerId = State(initialValue: projection.providerId)
        _providerName = State(initialValue: projection.providerName)
        _transactionType = State(initialValue: projection.transactionType)
    }

    // MARK: - Computed Properties (mirror Projection model)
    private var transactionAmountAvailable: Decimal {
        return currencyRate != 0 ? baseAmountAvailable * currencyRate : 0
    }

    private var investedAmountBase: Decimal {
        return Decimal(actualNumberOfStocks) * stockPrice / currencyRate
    }

    private var totalCost: Decimal {
        // Legacy fallback - actual cost calculation requires ModelContext via provider
        return projection.totalCost
    }

    private var investableAmountBase: Decimal {
        return baseAmountAvailable - totalCost
    }

    private var investableAmount: Decimal {
        return currencyRate != 0 ? investableAmountBase * currencyRate : 0
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
        return Decimal(actualNumberOfStocks) * stockPrice
    }

    private var remainingAmount: Decimal {
        return investableAmount - investedAmount
    }

    var body: some View {
        Form {
            // MARK: - Details Section
            Section {
                // Bank/Broker selection (always visible)
                if settings?.applyCost == true && !activeProviders.isEmpty {
                    NavigationLink(
                        destination: ProviderCostListView(
                            selectionMode: .single,
                            selectedProviderId: $providerId,
                            tab: tab
                        )
                    ) {
                        HStack {
                            Text("Bank/Broker")
                            Spacer()
                            Text(providerName ?? "None Selected")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: providerId) { _, newValue in
                        if let newId = newValue,
                            let provider = activeProviders.first(where: { $0.id == newId })
                        {
                            providerName = provider.displayName
                        }
                        checkForChanges()
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
                    .onChange(of: transactionType) { _, _ in checkForChanges() }

                    HStack {
                        TextField("Name (optional)", text: $name)
                            .focused($focusedField, equals: .name)
                            .onChange(of: name) { _, _ in checkForChanges() }

                        if !name.isEmpty {
                            Button(action: {
                                name = ""
                                checkForChanges()
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
                            .onChange(of: ticker) { _, _ in checkForChanges() }

                        if !ticker.isEmpty {
                            Button(action: {
                                ticker = ""
                                checkForChanges()
                            }) {
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }
                    }

                    DatePicker("Transaction Date", selection: $transactionDate, in: Date()..., displayedComponents: .date)
                        .onChange(of: transactionDate) { _, _ in
                            checkForChanges()
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
                // MARK: - Amounts Section
                Section {
                    HStack {
                        Text("Base Amount Available")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "Amount",
                            value: $baseAmountAvailable,
                            fractionDigits: 2,
                            suffix: baseCurrency,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .baseAmountAvailable)
                        .onChange(of: baseAmountAvailable) { _, _ in checkForChanges() }

                        if baseAmountAvailable != 0 {
                            Button(action: {
                                baseAmountAvailable = 0
                                checkForChanges()
                            }) {
                                Image(systemName: "xmark")
                            }
                            .circleBackground(fgColor: tab.color())
                        }
                    }

                    HStack {
                        Text("Transaction Amount")
                        Spacer()
                        Text(transactionAmountAvailable.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Available Amounts")
                        .foregroundStyle(tab.color())
                }

                // MARK: - Stock Details Section
                if transactionType != .deposit && transactionType != .withdrawal {
                    Section {
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
                            .onChange(of: stockPrice) { _, _ in checkForChanges() }

                            if stockPrice != 0 {
                                Button(action: {
                                    stockPrice = 0
                                    checkForChanges()
                                }) {
                                    Image(systemName: "xmark")
                                }
                                .circleBackground(fgColor: tab.color())
                            }
                        }

                        HStack {
                            Text("Projected Stocks")
                            Spacer()
                            Text("\(numberOfStocks)")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text(actualNumberOfStocks <= 0 ? "Projected Stocks" : "Actual Stocks")
                            Spacer()
                            TextField(
                                "0",
                                value: Binding(
                                    get: { actualNumberOfStocks <= 0 ? numberOfStocks : actualNumberOfStocks },
                                    set: { actualNumberOfStocks = $0 }
                                ),
                                format: .number
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .actualNumberOfStocks)
                            .onChange(of: actualNumberOfStocks) { _, newValue in
                                // Clamp to numberOfStocks
                                if newValue > numberOfStocks {
                                    actualNumberOfStocks = numberOfStocks
                                }
                                checkForChanges()
                            }

                            if actualNumberOfStocks != 0 {
                                Button(action: {
                                    actualNumberOfStocks = 0
                                    checkForChanges()
                                }) {
                                    Image(systemName: "xmark")
                                }
                                .circleBackground(fgColor: tab.color())
                            }
                        }

                        if actualNumberOfStocks > numberOfStocks {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("Actual stocks cannot exceed \(numberOfStocks)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    } header: {
                        Text("Stock Details")
                            .foregroundStyle(tab.color())
                    }
                }

                // MARK: - Currency Section
                Section {
                    NavigationLink(
                        destination: CurrencySelectionView(
                            selectedCurrency: $baseCurrency,
                            availableCurrencies: availableBaseCurrencies,
                            title: settings?.doubleCurrency ?? true ? "Base Currency" : "Currency",
                            tab: tab
                        )
                    ) {
                        HStack {
                            Text(settings?.doubleCurrency ?? true ? "Base Currency" : "Currency")
                            Spacer()
                            Text(baseCurrency)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: baseCurrency) { _, _ in
                        checkForChanges()
                        fetchCurrencyRate()
                    }

                    if settings?.doubleCurrency ?? true {
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
                            checkForChanges()
                            fetchCurrencyRate()
                        }

                        HStack {
                            Text("Currency Rate")

                            Button(action: {
                                fetchCurrencyRate()
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .circleBackground(fgColor: tab.color(), font: .body.bold(), padding: 5)
                            .disabled(isFetchingRate)

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
                            .onChange(of: currencyRate) { _, _ in checkForChanges() }

                            if currencyRate != 1.0 {
                                Button(action: {
                                    currencyRate = 1.0
                                    checkForChanges()
                                }) {
                                    Image(systemName: "xmark")
                                }
                                .circleBackground(fgColor: tab.color())
                            }
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
                            Text("Investable Amount")
                            Spacer()
                            Text(investableAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Invested Amount")
                            Spacer()
                            Text(investedAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Remaining Amount")
                            Spacer()
                            Text(remainingAmount.formatted(fractionDigits: 2, enforceMinimumDigits: true) + " " + transactionCurrency)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Results")
                            .foregroundStyle(tab.color())
                    }
                }

                // MARK: - Information Section
                Section {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(projection.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Modified")
                        Spacer()
                        Text(projection.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Information")
                        .foregroundStyle(tab.color())
                }
            }
        }
        .navigationTitle("Projection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent1 }
        .toolbar { toolbarContent2 }
    }

    enum Field: Hashable {
        case name, ticker, baseAmountAvailable, stockPrice, actualNumberOfStocks
        case currencyRate
    }

    // MARK: - Actions
    private func saveChanges() {
        projection.name = name.isEmpty ? nil : name
        projection.ticker = ticker
        projection.transactionDate = transactionDate
        projection.transactionType = transactionType
        projection.baseAmountAvailable = baseAmountAvailable
        projection.stockPrice = stockPrice
        projection.actualNumberOfStocks = actualNumberOfStocks
        projection.baseCurrency = baseCurrency
        projection.transactionCurrency = transactionCurrency
        projection.currencyRate = currencyRate
        projection.providerId = providerId
        projection.providerName = providerName
        projection.modifiedAt = Date()

        try? modelContext.save()
        hasChanges = false
        dismiss()
    }

    private func resetToSettings() {
        guard let settings = settings else { return }

        baseCurrency = settings.baseCurrency
        transactionCurrency = settings.transactionCurrency
        providerId = settings.defaultProviderId

        // Update provider name from selected provider
        if let providerId = providerId,
            let provider = activeProviders.first(where: { $0.id == providerId })
        {
            providerName = provider.displayName
        } else {
            providerName = nil
        }

        // Fetch the current currency rate
        fetchCurrencyRate()

        checkForChanges()
    }

    private func fetchCurrencyRate() {
        // Only fetch if double currency is enabled and currencies are different
        guard settings?.doubleCurrency ?? true else { return }
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
                    checkForChanges()
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

    private func checkForChanges() {
        let nameChanged = (projection.name ?? "") != name
        let tickerChanged = projection.ticker != ticker
        let transactionDateChanged = projection.transactionDate != transactionDate
        let transactionTypeChanged = projection.transactionType != transactionType
        let baseAmountChanged = projection.baseAmountAvailable != baseAmountAvailable
        let stockPriceChanged = projection.stockPrice != stockPrice
        let actualStocksChanged = projection.actualNumberOfStocks != actualNumberOfStocks
        let baseCurrencyChanged = projection.baseCurrency != baseCurrency
        let transactionCurrencyChanged = projection.transactionCurrency != transactionCurrency
        let currencyRateChanged = projection.currencyRate != currencyRate
        let providerIdChanged = projection.providerId != providerId
        let providerNameChanged = projection.providerName != providerName

        hasChanges = nameChanged || tickerChanged || transactionDateChanged || transactionTypeChanged ||
            baseAmountChanged || stockPriceChanged || actualStocksChanged ||
            baseCurrencyChanged || transactionCurrencyChanged || currencyRateChanged ||
            providerIdChanged || providerNameChanged
    }

    // MARK: - Keyboard Navigation
    func clearCurrentField() {
        switch focusedField {
        case .name:
            name = ""
        case .ticker:
            ticker = ""
        case .baseAmountAvailable:
            baseAmountAvailable = 0
        case .stockPrice:
            stockPrice = 0
        case .actualNumberOfStocks:
            actualNumberOfStocks = 0
        case .currencyRate:
            currencyRate = 1.0
        case .none:
            break
        }
        checkForChanges()
    }

    private func moveToPreviousField() {
        switch focusedField {
        case .ticker:
            focusedField = .name
        case .baseAmountAvailable:
            focusedField = .ticker
        case .stockPrice:
            focusedField = .baseAmountAvailable
        case .actualNumberOfStocks:
            focusedField = .stockPrice
        case .currencyRate:
            focusedField = .actualNumberOfStocks
        case .name, .none:
            focusedField = nil
        }
    }

    private func moveToNextField() {
        let doubleCurrency = settings?.doubleCurrency ?? true

        switch focusedField {
        case .name:
            focusedField = .ticker
        case .ticker:
            focusedField = .baseAmountAvailable
        case .baseAmountAvailable:
            focusedField = .stockPrice
        case .stockPrice:
            focusedField = .actualNumberOfStocks
        case .actualNumberOfStocks:
            if doubleCurrency {
                focusedField = .currencyRate
            } else {
                focusedField = nil
            }
        case .currencyRate, .none:
            focusedField = nil
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent1: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                saveChanges()
            }) {
                Image(systemName: "checkmark")
                    .capsuleBackground(fgColor: tab.color(), font: .body, hPadding: 8, vPadding: 6, prominent: hasChanges)
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent2: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            KeyboardToolbarButton.button(.clear) { clearCurrentField() }

            Spacer()

            KeyboardToolbarButton.button(.previous) { moveToPreviousField() }

            KeyboardToolbarButton.button(.next) { moveToNextField() }

            KeyboardToolbarButton.button(.done(tab.color())) { focusedField = nil }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectionDetailView(
            projection: Projection(
                baseAmountAvailable: 10000,
                stockPrice: 150,
                ticker: "AAPL"
            ),
            tab: .projection
        )
    }
}
