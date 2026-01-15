//
//  Projection.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftData

@Model
final class Projection {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var transactionDate: Date = Date()
    var name: String?

    // Stock Details
    var ticker: String = ""

    // Available Amounts (stored as Strings for Decimal precision)
    private var baseAmountAvailableString: String = "0"

    // Stock Info (stored as Strings for Decimal precision)
    private var stockPriceString: String = "0"
    private var actualNumberOfStocksString: String = "0"

    // Currency Info
    var baseCurrency: String = "USD"
    var transactionCurrency: String = "EUR"
    private var currencyRateString: String = "1.0"

    // Costs (stored as Strings for Decimal precision)
    private var fixedCostString: String = "0"
    private var variableCostString: String = "0"
    private var maximumCostString: String? = nil

    // Bank/Broker and Provider
    var bankBrokerName: String = ""
    var providerName: String? = nil
    private var transactionTypeString: String = "Buy"

    init(
        baseAmountAvailable: Decimal = 0,
        stockPrice: Decimal = 0,
        actualNumberOfStocks: Int = 0,
        ticker: String = "",
        currencyRate: Decimal = 1.0,
        fixedCost: Decimal = 0,
        variableCost: Decimal = 0,
        maximumCost: Decimal? = nil,
        name: String? = nil,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
        bankBrokerName: String = "",
        providerName: String? = nil,
        transactionDate: Date = Date(),
        transactionType: TransactionType = .buy
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.transactionDate = transactionDate
        self.name = name
        self.ticker = ticker
        self.baseCurrency = baseCurrency
        self.transactionCurrency = transactionCurrency
        self.bankBrokerName = bankBrokerName
        self.providerName = providerName
        self.transactionTypeString = transactionType.rawValue

        // Store Decimals as Strings for perfect precision
        self.baseAmountAvailableString = "\(baseAmountAvailable)"
        self.stockPriceString = "\(stockPrice)"
        self.actualNumberOfStocksString = "\(actualNumberOfStocks)"
        self.currencyRateString = "\(currencyRate)"
        self.fixedCostString = "\(fixedCost)"
        self.variableCostString = "\(variableCost)"
        self.maximumCostString = maximumCost.map { "\($0)" }
    }
}

// MARK: - Decimal Properties (Translation Layer)
extension Projection {
    /// Base amount available as Decimal with perfect precision
    var baseAmountAvailable: Decimal {
        get { Decimal(string: baseAmountAvailableString) ?? 0 }
        set {
            baseAmountAvailableString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Stock price as Decimal with perfect precision
    var stockPrice: Decimal {
        get { Decimal(string: stockPriceString) ?? 0 }
        set {
            stockPriceString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Currency rate as Decimal with perfect precision
    var currencyRate: Decimal {
        get { Decimal(string: currencyRateString) ?? 1.0 }
        set {
            currencyRateString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Fixed cost as Decimal with perfect precision
    var fixedCost: Decimal {
        get { Decimal(string: fixedCostString) ?? 0 }
        set {
            fixedCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Variable cost as Decimal with perfect precision
    var variableCost: Decimal {
        get { Decimal(string: variableCostString) ?? 0 }
        set {
            variableCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Maximum cost as Decimal with perfect precision
    var maximumCost: Decimal? {
        get {
            guard let string = maximumCostString else { return nil }
            return Decimal(string: string)
        }
        set {
            maximumCostString = newValue.map { "\($0)" }
            modifiedAt = Date()
        }
    }

    /// Actual number of stocks (user adjustable, must be <= numberOfStocks)
    var actualNumberOfStocks: Int {
        get {
            return Int(actualNumberOfStocksString) ?? 0
        }
        set {
            // Clamp to projected numberOfStocks
            let clamped = min(newValue, numberOfStocks)
            actualNumberOfStocksString = "\(max(0, clamped))"
            modifiedAt = Date()
        }
    }

    /// Transaction type (buy or sell)
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeString) ?? .buy }
        set {
            transactionTypeString = newValue.rawValue
            modifiedAt = Date()
        }
    }
}

// MARK: - Computed Properties
extension Projection {
    /// Transaction amount available (converted from base currency)
    var transactionAmountAvailable: Decimal {
        return currencyRate != 0 ? baseAmountAvailable * currencyRate : 0
    }

    /// Total cost including fixed and variable costs, capped by maximum if set
    /// Formula: MAX(150, fixedCost + (investedAmountInBaseCurrency * variableCost))
    var totalCost: Decimal {
        // Variable cost applies to the invested amount in base currency
        let investedAmountBase = investedAmount / currencyRate
        let variableCostAmount = investedAmountBase * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        // Apply minimum cost of 150
        let costWithMinimum = max(150, totalWithoutMax)

        // Apply maximum cost cap if set
        if let maxCost = maximumCost, maxCost > 0 {
            return min(costWithMinimum, maxCost)
        }
        return costWithMinimum
    }

    /// Net amount available after costs in base currency
    var investableAmountBase: Decimal {
        return baseAmountAvailable - totalCost
    }

    /// Amount available for investment after costs, converted to transaction currency
    var investableAmount: Decimal {
        let netAmount = investableAmountBase
        return currencyRate != 0 ? netAmount * currencyRate : 0
    }

    /// Number of whole stocks that can be purchased (projected)
    var numberOfStocks: Int {
        guard stockPrice > 0 else { return 0 }

        let stocks = investableAmount / stockPrice

        // Use Decimal's built-in rounding to floor
        var stocksValue = stocks
        var rounded = Decimal()
        NSDecimalRound(&rounded, &stocksValue, 0, .down)

        return Int(truncating: rounded as NSNumber)
    }

    /// Total amount invested (actual stocks × stock price in transaction currency)
    var investedAmount: Decimal {
        return Decimal(actualNumberOfStocks) * stockPrice
    }

    /// Remaining amount after purchasing actual stocks (in transaction currency)
    var remainingAmount: Decimal {
        return investableAmount - investedAmount
    }
}

// MARK: - Validation
extension Projection {
    /// Validates that the projection data is valid
    var isValid: Bool {
        guard baseAmountAvailable > 0 else { return false }
        guard stockPrice > 0 else { return false }
        guard actualNumberOfStocks <= numberOfStocks else { return false }
        guard transactionDate >= Date().addingTimeInterval(-86400) else { return false } // Allow today
        return true
    }

    /// Returns a list of validation errors
    var validationErrors: [String] {
        var errors: [String] = []

        if baseAmountAvailable <= 0 {
            errors.append("Base amount must be greater than 0")
        }

        if stockPrice <= 0 {
            errors.append("Stock price must be greater than 0")
        }

        if actualNumberOfStocks > numberOfStocks {
            errors.append("Actual number of stocks cannot exceed \(numberOfStocks)")
        }

        if transactionDate < Date().addingTimeInterval(-86400) {
            errors.append("Transaction date must be today or in the future")
        }

        return errors
    }
}

// MARK: - Helper Methods
extension Projection {
    /// Reset to Settings defaults
    func resetToSettings(_ settings: Settings) {
        self.baseCurrency = settings.baseCurrency
        self.transactionCurrency = settings.transactionCurrency
        self.currencyRate = settings.effectiveCurrencyRate
        self.bankBrokerName = settings.bankBrokerName
        self.providerName = nil

        // Reset costs if Apply Cost is enabled
        if settings.applyCost {
            self.fixedCost = settings.defaultFixedCost
            self.variableCost = settings.defaultVariableCost
            self.maximumCost = settings.defaultMaximumCost
        } else {
            self.fixedCost = 0
            self.variableCost = 0
            self.maximumCost = nil
        }

        self.modifiedAt = Date()
    }

    /// Load costs from a BankBrokerCost provider
    func loadFromProvider(_ provider: BankBrokerCost) {
        self.fixedCost = provider.fixedCost
        self.variableCost = provider.variableCostRate
        self.maximumCost = provider.maximumCost
        self.providerName = provider.bankBrokerName
        self.modifiedAt = Date()
    }
}
