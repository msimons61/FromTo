//
//  InvestmentViewModel.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation
import Combine

@MainActor
class InvestmentViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var availableAmount: Decimal = 0 {
        didSet { recalculate() }
    }
    @Published var stockPrice: Decimal = 0 {
        didSet { recalculate() }
    }
    @Published var currencyRate: Decimal = 1.0 {
        didSet { recalculate() }
    }
    @Published var fixedCost: Decimal = 0 {
        didSet { recalculate() }
    }
    @Published var variableCost: Decimal = 0 {
        didSet { recalculate() }
    }
    @Published var maximumCost: Decimal? {
        didSet { recalculate() }
    }

    @Published private(set) var totalCost: Decimal = 0
    @Published private(set) var investableAmount: Decimal = 0
    @Published private(set) var numberOfStocks: Int = 0
    @Published private(set) var investedAmount: Decimal = 0

    // MARK: - Computed Properties
    var remainingAmount: Decimal {
        return investableAmount - investedAmount
    }

    private var settings: SettingsData
    private var cancellables = Set<AnyCancellable>()
    private var isInitialized = false

    // MARK: - Initialization
    init(settings: SettingsData) {
        self.settings = settings
        loadFromDefaults()
        loadDefaultCosts()
        setupPersistence()
        isInitialized = true
        recalculate()
    }

    // MARK: - Methods
    private func recalculate() {
        guard isInitialized else { return }

        // Calculate Total Cost
        let variableCostAmount = availableAmount * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        let newTotalCost: Decimal
        if let maxCost = maximumCost, maxCost > 0 {
            newTotalCost = min(totalWithoutMax, maxCost)
        } else {
            newTotalCost = totalWithoutMax
        }

        // Calculate Investable Amount
        let netAmount = availableAmount - newTotalCost
        let newInvestableAmount: Decimal
        if currencyRate != 0 {
            newInvestableAmount = netAmount / currencyRate
        } else {
            newInvestableAmount = 0
        }

        // Calculate Number of Stocks
        let newNumberOfStocks: Int
        if stockPrice > 0 {
            let stocks = newInvestableAmount / stockPrice

            // Use Decimal's built-in rounding to floor
            var stocksValue = stocks
            var rounded = Decimal()
            NSDecimalRound(&rounded, &stocksValue, 0, .down)
            newNumberOfStocks = Int(truncating: rounded as NSNumber)
        } else {
            newNumberOfStocks = 0
        }

        // Calculate Invested Amount
        let newInvestedAmount = Decimal(newNumberOfStocks) * stockPrice

        // Update all properties (we're already on @MainActor)
        totalCost = newTotalCost
        investableAmount = newInvestableAmount
        numberOfStocks = newNumberOfStocks
        investedAmount = newInvestedAmount
    }

    func reloadCostsFromSettings() {
        currencyRate = settings.currencyRate
        fixedCost = settings.defaultFixedCost
        variableCost = settings.defaultVariableCost
        maximumCost = settings.defaultMaximumCost
    }

    private func loadDefaultCosts() {
        // Check if currencyRate was never saved (still at default 1.0) after loading from UserDefaults
        let hasSavedCurrencyRate = UserDefaults.standard.string(forKey: "com.fromto.investment.currencyRate") != nil

        // If no saved currency rate, load from settings
        if !hasSavedCurrencyRate {
            currencyRate = settings.currencyRate
        }

        // If all costs are at default values, load them from settings too
        if fixedCost == 0 && variableCost == 0 && maximumCost == nil {
            fixedCost = settings.defaultFixedCost
            variableCost = settings.defaultVariableCost
            maximumCost = settings.defaultMaximumCost
        }
    }

    // MARK: - Persistence
    private func setupPersistence() {
        // Save to UserDefaults whenever any property changes
        Publishers.CombineLatest4(
            $availableAmount,
            $stockPrice,
            $currencyRate,
            $fixedCost
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.saveToDefaults()
        }
        .store(in: &cancellables)

        Publishers.CombineLatest(
            $variableCost,
            $maximumCost
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            self?.saveToDefaults()
        }
        .store(in: &cancellables)
    }

    private func saveToDefaults() {
        UserDefaults.standard.set("\(availableAmount)", forKey: "com.fromto.investment.availableAmount")
        UserDefaults.standard.set("\(stockPrice)", forKey: "com.fromto.investment.stockPrice")
        UserDefaults.standard.set("\(currencyRate)", forKey: "com.fromto.investment.currencyRate")
        UserDefaults.standard.set("\(fixedCost)", forKey: "com.fromto.investment.fixedCost")
        UserDefaults.standard.set("\(variableCost)", forKey: "com.fromto.investment.variableCost")

        if let maxCost = maximumCost {
            UserDefaults.standard.set("\(maxCost)", forKey: "com.fromto.investment.maximumCost")
        } else {
            UserDefaults.standard.removeObject(forKey: "com.fromto.investment.maximumCost")
        }
    }

    private func loadFromDefaults() {
        if let savedAvailable = UserDefaults.standard.string(forKey: "com.fromto.investment.availableAmount"),
           let value = Decimal(string: savedAvailable) {
            availableAmount = value
        }

        if let savedStock = UserDefaults.standard.string(forKey: "com.fromto.investment.stockPrice"),
           let value = Decimal(string: savedStock) {
            stockPrice = value
        }

        if let savedRate = UserDefaults.standard.string(forKey: "com.fromto.investment.currencyRate"),
           let value = Decimal(string: savedRate) {
            currencyRate = value
        }

        if let savedFixed = UserDefaults.standard.string(forKey: "com.fromto.investment.fixedCost"),
           let value = Decimal(string: savedFixed) {
            fixedCost = value
        }

        if let savedVariable = UserDefaults.standard.string(forKey: "com.fromto.investment.variableCost"),
           let value = Decimal(string: savedVariable) {
            variableCost = value
        }

        if let savedMaximum = UserDefaults.standard.string(forKey: "com.fromto.investment.maximumCost"),
           let value = Decimal(string: savedMaximum) {
            maximumCost = value
        }
    }
}
