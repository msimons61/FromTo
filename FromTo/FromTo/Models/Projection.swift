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

    // Provider reference (replaces individual cost fields)
    var providerId: UUID? = nil
    var providerName: String? = nil

    private var transactionTypeString: String = "Buy"

    init(
        baseAmountAvailable: Decimal = 0,
        stockPrice: Decimal = 0,
        actualNumberOfStocks: Int = 0,
        ticker: String = "",
        currencyRate: Decimal = 1.0,
        name: String? = nil,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
        providerId: UUID? = nil,
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
        self.providerId = providerId
        self.providerName = providerName
        self.transactionTypeString = transactionType.rawValue

        // Store Decimals as Strings for perfect precision
        self.baseAmountAvailableString = "\(baseAmountAvailable)"
        self.stockPriceString = "\(stockPrice)"
        self.actualNumberOfStocksString = "\(actualNumberOfStocks)"
        self.currencyRateString = "\(currencyRate)"
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

    /// Total cost calculated from provider, with legacy 150 minimum
    /// Returns 150 if no provider is set (legacy behavior)
    var totalCost: Decimal {
        // If no provider, return legacy minimum of 150
        guard providerId != nil else {
            return 150
        }

        // Note: Actual calculation requires ModelContext to fetch provider
        // This property should not be used directly - use calculateTotalCostFromProvider instead
        // Returning 150 as fallback
        return 150
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
        self.providerId = settings.defaultProviderId
        self.providerName = nil
        self.modifiedAt = Date()
    }

    /// Load costs from a BankBrokerProvider
    func loadFromProvider(_ provider: BankBrokerProvider) {
        self.providerId = provider.id
        self.providerName = provider.displayName
        self.modifiedAt = Date()
    }

    /// Calculate total cost from provider using CostCalculationService
    /// - Parameter modelContext: The model context to fetch provider
    /// - Returns: The calculated net cost, or 150 if no provider is set
    func calculateTotalCostFromProvider(modelContext: ModelContext) -> Decimal {
        guard let providerId = providerId else {
            return 150 // Legacy minimum
        }

        // Fetch provider from context
        let descriptor = FetchDescriptor<BankBrokerProvider>(
            predicate: #Predicate { $0.id == providerId }
        )

        guard let provider = try? modelContext.fetch(descriptor).first else {
            return 150 // Fallback if provider not found
        }

        // Use CostCalculationService to calculate cost
        let result = CostCalculationService.shared.calculateCost(
            provider: provider,
            transactionAmount: investedAmount,
            baseCurrency: baseCurrency,
            transactionCurrency: transactionCurrency,
            currencyRate: currencyRate
        )

        return result.netCost
    }
}
