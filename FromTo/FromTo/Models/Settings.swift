//
//  Settings.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Settings {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // Display Settings
    var displayModeString: String = "system" // "light", "dark", "system"

    // Currency Settings
    var doubleCurrency: Bool = true // Controls currency field visibility
    var baseCurrency: String = "USD"
    private var transactionCurrencyString: String = "EUR"
    private var currencyRateString: String = "1.0"

    // Cost Settings
    var applyCost: Bool = true // Controls cost feature visibility
    var bankBrokerName: String = ""

    // Default Costs (stored as Strings for Decimal precision)
    private var defaultFixedCostString: String = "0"
    private var defaultVariableCostString: String = "0"
    private var defaultMaximumCostString: String? = nil

    init(
        displayMode: DisplayMode = .system,
        doubleCurrency: Bool = true,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
        currencyRate: Decimal = 1.0,
        applyCost: Bool = true,
        bankBrokerName: String = "",
        defaultFixedCost: Decimal = 0,
        defaultVariableCost: Decimal = 0,
        defaultMaximumCost: Decimal? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.displayModeString = displayMode.rawValue
        self.doubleCurrency = doubleCurrency
        self.baseCurrency = baseCurrency
        self.transactionCurrencyString = transactionCurrency
        self.currencyRateString = "\(currencyRate)"
        self.applyCost = applyCost
        self.bankBrokerName = bankBrokerName
        self.defaultFixedCostString = "\(defaultFixedCost)"
        self.defaultVariableCostString = "\(defaultVariableCost)"
        self.defaultMaximumCostString = defaultMaximumCost.map { "\($0)" }
    }
}

// MARK: - Display Mode
extension Settings {
    var displayMode: DisplayMode {
        get { DisplayMode(rawValue: displayModeString) ?? .system }
        set {
            displayModeString = newValue.rawValue
            modifiedAt = Date()
        }
    }

    var colorScheme: ColorScheme? {
        switch displayMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Currency Properties
extension Settings {
    /// Transaction currency - returns baseCurrency if doubleCurrency is false
    var transactionCurrency: String {
        get { doubleCurrency ? transactionCurrencyString : baseCurrency }
        set {
            transactionCurrencyString = newValue
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

    /// Effective currency rate - returns 1.0 if doubleCurrency is false or currencies are the same
    var effectiveCurrencyRate: Decimal {
        if !doubleCurrency || baseCurrency == transactionCurrency {
            return 1.0
        }
        return currencyRate
    }
}

// MARK: - Cost Properties
extension Settings {
    /// Default fixed cost as Decimal with perfect precision
    var defaultFixedCost: Decimal {
        get { Decimal(string: defaultFixedCostString) ?? 0 }
        set {
            defaultFixedCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Default variable cost as Decimal with perfect precision
    var defaultVariableCost: Decimal {
        get { Decimal(string: defaultVariableCostString) ?? 0 }
        set {
            defaultVariableCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Default maximum cost as Decimal with perfect precision
    var defaultMaximumCost: Decimal? {
        get {
            guard let string = defaultMaximumCostString else { return nil }
            return Decimal(string: string)
        }
        set {
            defaultMaximumCostString = newValue.map { "\($0)" }
            modifiedAt = Date()
        }
    }
}

// MARK: - Helper Methods
extension Settings {
    /// Available currencies list
    var availableCurrencies: [String] {
        return Locale.commonISOCurrencyCodes.sorted()
    }

    /// Creates default settings instance
    static func createDefault() -> Settings {
        return Settings()
    }

    /// Update currency rate if currencies match
    func updateCurrencyRateIfNeeded() {
        if baseCurrency == transactionCurrency {
            currencyRate = 1.0
        }
    }

    /// Sync currencies when doubleCurrency is disabled
    func syncCurrenciesIfNeeded() {
        if !doubleCurrency {
            transactionCurrencyString = baseCurrency
            currencyRate = 1.0
        }
    }

    /// Reset costs when applyCost is disabled
    func resetCostsIfNeeded() {
        if !applyCost {
            defaultFixedCost = 0
            defaultVariableCost = 0
            defaultMaximumCost = nil
        }
    }
}
