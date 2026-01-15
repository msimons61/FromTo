//
//  ProjectionDetailView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct ProjectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsQuery: [Settings]
    @Query private var allProviders: [BankBrokerCost]

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
    @State private var fixedCost: Decimal
    @State private var variableCost: Decimal
    @State private var maximumCost: Decimal?
    @State private var bankBrokerName: String
    @State private var providerName: String?
    @State private var transactionType: TransactionType

    @FocusState private var focusedField: Field?
    @State private var hasChanges = false
    @State private var isFetchingRate = false

    private var settings: Settings? {
        settingsQuery.first
    }

    private var activeProviders: [BankBrokerCost] {
        allProviders.filter { $0.isActive(on: transactionDate) }
    }

    private var uniqueProviderNames: [String] {
        let names = activeProviders.map { $0.bankBrokerName }
        return Array(Set(names)).sorted()
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
        _fixedCost = State(initialValue: projection.fixedCost)
        _variableCost = State(initialValue: projection.variableCost)
        _maximumCost = State(initialValue: projection.maximumCost)
        _bankBrokerName = State(initialValue: projection.bankBrokerName)
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
        let variableCostAmount = investedAmountBase * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount
        let costWithMinimum = max(150, totalWithoutMax)

        if let maxCost = maximumCost, maxCost > 0 {
            return min(costWithMinimum, maxCost)
        }
        return costWithMinimum
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
                Picker("Transaction Type", selection: $transactionType) {
                    ForEach(TransactionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .onChange(of: transactionType) { _, _ in hasChanges = true }

                HStack {
                    TextField("Name (optional)", text: $name)
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

                DatePicker("Transaction Date", selection: $transactionDate, in: Date()..., displayedComponents: .date)
                    .onChange(of: transactionDate) { _, _ in
                        hasChanges = true
                        fetchCurrencyRate()
                    }

            } header: {
                Text("Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Bank/Broker Section
            Section {
                if settings?.applyCost == true && !uniqueProviderNames.isEmpty {
                    // Show picker when Apply Cost is enabled and providers exist
                    NavigationLink(
                        destination: ProviderSelectionView(
                            selectedProvider: $bankBrokerName,
                            availableProviders: uniqueProviderNames,
                            tab: tab
                        )
                    ) {
                        HStack {
                            Text("Bank/Broker")
                            Spacer()
                            Text(bankBrokerName.isEmpty ? "None" : bankBrokerName)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: bankBrokerName) { _, newValue in
                        // Load costs from the selected provider
                        if let provider = activeProviders.first(where: { $0.bankBrokerName == newValue }) {
                            loadFromProvider(provider)
                        }
                        hasChanges = true
                    }
                } else {
                    // Show text field when Apply Cost is disabled or no providers
                    HStack {
                        TextField("Bank/Broker Name", text: $bankBrokerName)
                            .focused($focusedField, equals: .bankBrokerName)
                            .onChange(of: bankBrokerName) { _, _ in hasChanges = true }
                    }
                }
            } header: {
                Text("Bank/Broker")
                    .foregroundStyle(tab.color())
            }

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
                    .onChange(of: baseAmountAvailable) { _, _ in hasChanges = true }
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
                        .onChange(of: stockPrice) { _, _ in hasChanges = true }
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
                        TextField("0", value: Binding(
                            get: { actualNumberOfStocks <= 0 ? numberOfStocks : actualNumberOfStocks },
                            set: { actualNumberOfStocks = $0 }
                        ), format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .actualNumberOfStocks)
                            .onChange(of: actualNumberOfStocks) { _, newValue in
                                // Clamp to numberOfStocks
                                if newValue > numberOfStocks {
                                    actualNumberOfStocks = numberOfStocks
                                }
                                hasChanges = true
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
                    hasChanges = true
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
                        hasChanges = true
                        fetchCurrencyRate()
                    }

                    HStack {
                        Text("Currency Rate")
                        
                        Button(action: {
                            fetchCurrencyRate()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .circleBackground(fgColor: tab.color(), font: .body.bold(), size: 5)
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
                        .onChange(of: currencyRate) { _, _ in hasChanges = true }
                    }
                }
            } header: {
                Text("Currency")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Costs Section (conditional on applyCost)
            if (settings?.applyCost ?? true) && transactionType != .deposit && transactionType != .withdrawal {
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
                        Text("Variable Cost Rate")
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
                        Button(action: {
                            resetToSettings()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .circleBackground(fgColor: tab.color(), font: .body.bold(), size: 5)
                    }
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
        .navigationTitle("Projection")
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

            ToolbarItemGroup(placement: .keyboard) {
                Button(action: { clearCurrentField() }) {
                    Text("Clear")
                        .kbCapsuleBackground(color: .red)
                }

                Spacer()

                Button(action: { moveToPreviousField() }) {
                    Image(systemName: "chevron.up")
                        .kbCapsuleBackground(color: .teal)
                }

                Button(action: { moveToNextField() }) {
                    Image(systemName: "chevron.down")
                        .kbCapsuleBackground(color: .blue)
                }

                Button(action: { focusedField = nil }) {
                    Text("Done")
                        .kbCapsuleBackground(color: .green)
                }
            }
        }
        .tint(tab.color())
    }

    enum Field: Hashable {
        case ticker, baseAmountAvailable, stockPrice, actualNumberOfStocks
        case currencyRate, bankBrokerName
        case fixedCost, variableCost, maximumCost
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
        projection.fixedCost = fixedCost
        projection.variableCost = variableCost
        projection.maximumCost = maximumCost
        projection.bankBrokerName = bankBrokerName
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
        bankBrokerName = settings.bankBrokerName
        providerName = nil

        if settings.applyCost {
            fixedCost = settings.defaultFixedCost
            variableCost = settings.defaultVariableCost
            maximumCost = settings.defaultMaximumCost
        } else {
            fixedCost = 0
            variableCost = 0
            maximumCost = nil
        }

        // Fetch the current currency rate
        fetchCurrencyRate()

        hasChanges = true
    }

    private func loadFromProvider(_ provider: BankBrokerCost) {
        fixedCost = provider.fixedCost
        variableCost = provider.variableCostRate
        maximumCost = provider.maximumCost
        providerName = provider.bankBrokerName
        hasChanges = true
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

    // MARK: - Keyboard Navigation
    private func clearCurrentField() {
        switch focusedField {
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
        case .bankBrokerName:
            bankBrokerName = ""
        case .fixedCost:
            fixedCost = 0
        case .variableCost:
            variableCost = 0
        case .maximumCost:
            maximumCost = nil
        default:
            break
        }
        hasChanges = true
    }

    private func moveToPreviousField() {
        let doubleCurrency = settings?.doubleCurrency ?? true

        switch focusedField {
        case .baseAmountAvailable:
            focusedField = .ticker
        case .stockPrice:
            focusedField = .baseAmountAvailable
        case .actualNumberOfStocks:
            focusedField = .stockPrice
        case .currencyRate:
            focusedField = .actualNumberOfStocks
        case .bankBrokerName:
            if doubleCurrency {
                focusedField = .currencyRate
            } else {
                focusedField = .actualNumberOfStocks
            }
        case .fixedCost:
            focusedField = .bankBrokerName
        case .variableCost:
            focusedField = .fixedCost
        case .maximumCost:
            focusedField = .variableCost
        default:
            focusedField = nil
        }
    }

    private func moveToNextField() {
        let doubleCurrency = settings?.doubleCurrency ?? true
        let applyCost = settings?.applyCost ?? true

        switch focusedField {
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
                focusedField = .bankBrokerName
            }
        case .currencyRate:
            focusedField = .bankBrokerName
        case .bankBrokerName:
            if applyCost {
                focusedField = .fixedCost
            } else {
                focusedField = nil
            }
        case .fixedCost:
            focusedField = .variableCost
        case .variableCost:
            focusedField = .maximumCost
        case .maximumCost:
            focusedField = nil
        default:
            focusedField = .ticker
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
