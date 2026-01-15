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

    // Cost Settings
    var applyCost: Bool = true // Controls cost feature visibility
    var bankBrokerName: String = ""

    // Default Costs (stored as Strings for Decimal precision)
    private var defaultFixedCostString: String = "0"
    private var defaultVariableCostString: String = "0"
    private var defaultMaximumCostString: String? = nil

    // Currency List Cache (synced via iCloud)
    private var cachedSupportedCurrenciesString: String? = nil
    var lastCurrencyFetchDate: Date? = nil

    init(
        displayMode: DisplayMode = .system,
        doubleCurrency: Bool = true,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
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

    /// Effective currency rate - always returns 1.0 (rates are now fetched dynamically)
    var effectiveCurrencyRate: Decimal {
        return 1.0
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

// MARK: - Cached Currency List
extension Settings {
    /// Cached supported currencies from Frankfurter API
    var cachedSupportedCurrencies: [String]? {
        get {
            guard let string = cachedSupportedCurrenciesString else { return nil }
            return string.components(separatedBy: ",").filter { !$0.isEmpty }
        }
        set {
            if let currencies = newValue {
                cachedSupportedCurrenciesString = currencies.joined(separator: ",")
            } else {
                cachedSupportedCurrenciesString = nil
            }
            modifiedAt = Date()
        }
    }

    /// Check if currency cache needs refresh (older than 24 hours)
    var needsCurrencyRefresh: Bool {
        guard let lastFetch = lastCurrencyFetchDate else { return true }
        let dayInSeconds: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(lastFetch) > dayInSeconds
    }
}

// MARK: - Helper Methods
extension Settings {
    /// Available currencies list (uses cached list if available, falls back to static list)
    var availableCurrencies: [String] {
        return cachedSupportedCurrencies ?? CurrencyRateService.supportedCurrencies
    }

    /// Creates default settings instance
    static func createDefault() -> Settings {
        return Settings()
    }

    /// Sync currencies when doubleCurrency is disabled
    func syncCurrenciesIfNeeded() {
        if !doubleCurrency {
            transactionCurrencyString = baseCurrency
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
