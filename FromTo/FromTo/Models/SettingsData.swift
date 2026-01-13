//
//  SettingsData.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI
import Combine

class SettingsData: ObservableObject {
    // MARK: - Published Properties
    @Published var displayMode: DisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: "com.fromto.settings.displayMode")
        }
    }

    @Published var isDoubleCurrencyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDoubleCurrencyEnabled, forKey: "com.fromto.settings.isDoubleCurrencyEnabled")
            syncCurrenciesIfNeeded()
        }
    }

    @Published var isApplyCostEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isApplyCostEnabled, forKey: "com.fromto.settings.isApplyCostEnabled")
            resetCostsIfNeeded()
        }
    }

    @Published var fromCurrency: String {
        didSet {
            UserDefaults.standard.set(fromCurrency, forKey: "com.fromto.settings.fromCurrency")
            updateCurrencyRateIfNeeded()
            syncCurrenciesIfNeeded()
        }
    }

    @Published var toCurrency: String {
        didSet {
            UserDefaults.standard.set(toCurrency, forKey: "com.fromto.settings.toCurrency")
            updateCurrencyRateIfNeeded()
        }
    }

    @Published var currencyRate: Decimal {
        didSet {
            UserDefaults.standard.set("\(currencyRate)", forKey: "com.fromto.settings.currencyRate")
        }
    }

    @Published var defaultFixedCost: Decimal {
        didSet {
            UserDefaults.standard.set("\(defaultFixedCost)", forKey: "com.fromto.settings.defaultFixedCost")
        }
    }

    @Published var defaultVariableCost: Decimal {
        didSet {
            UserDefaults.standard.set("\(defaultVariableCost)", forKey: "com.fromto.settings.defaultVariableCost")
        }
    }

    @Published var defaultMaximumCost: Decimal? {
        didSet {
            if let value = defaultMaximumCost {
                UserDefaults.standard.set("\(value)", forKey: "com.fromto.settings.defaultMaximumCost")
            } else {
                UserDefaults.standard.removeObject(forKey: "com.fromto.settings.defaultMaximumCost")
            }
        }
    }

    // MARK: - Currency List
    var availableCurrencies: [String] {
        return Locale.commonISOCurrencyCodes.sorted()
    }

    // MARK: - Color Scheme
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

    // MARK: - Initialization
    init() {
        // Load from UserDefaults
        if let savedMode = UserDefaults.standard.string(forKey: "com.fromto.settings.displayMode"),
           let mode = DisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        } else {
            self.displayMode = .system
        }

        // Use object(forKey:) to distinguish "not set" from "false" for default=true
        if let saved = UserDefaults.standard.object(forKey: "com.fromto.settings.isDoubleCurrencyEnabled") as? Bool {
            self.isDoubleCurrencyEnabled = saved
        } else {
            self.isDoubleCurrencyEnabled = true
        }

        if let saved = UserDefaults.standard.object(forKey: "com.fromto.settings.isApplyCostEnabled") as? Bool {
            self.isApplyCostEnabled = saved
        } else {
            self.isApplyCostEnabled = true
        }

        self.fromCurrency = UserDefaults.standard.string(forKey: "com.fromto.settings.fromCurrency") ?? "USD"
        self.toCurrency = UserDefaults.standard.string(forKey: "com.fromto.settings.toCurrency") ?? "EUR"

        if let rateString = UserDefaults.standard.string(forKey: "com.fromto.settings.currencyRate"),
           let rate = Decimal(string: rateString) {
            self.currencyRate = rate
        } else {
            self.currencyRate = 1.0
        }

        if let fixedString = UserDefaults.standard.string(forKey: "com.fromto.settings.defaultFixedCost"),
           let fixed = Decimal(string: fixedString) {
            self.defaultFixedCost = fixed
        } else {
            self.defaultFixedCost = 0
        }

        if let variableString = UserDefaults.standard.string(forKey: "com.fromto.settings.defaultVariableCost"),
           let variable = Decimal(string: variableString) {
            self.defaultVariableCost = variable
        } else {
            self.defaultVariableCost = 0
        }

        if let maxString = UserDefaults.standard.string(forKey: "com.fromto.settings.defaultMaximumCost"),
           let max = Decimal(string: maxString) {
            self.defaultMaximumCost = max
        } else {
            self.defaultMaximumCost = nil
        }
    }

    // MARK: - Helper Methods
    private func updateCurrencyRateIfNeeded() {
        if fromCurrency == toCurrency {
            currencyRate = 1.0
        }
    }

    private func syncCurrenciesIfNeeded() {
        if !isDoubleCurrencyEnabled {
            toCurrency = fromCurrency
            // currencyRate will be set to 1.0 automatically via updateCurrencyRateIfNeeded()
        }
    }

    private func resetCostsIfNeeded() {
        if !isApplyCostEnabled {
            defaultFixedCost = 0
            defaultVariableCost = 0
            defaultMaximumCost = nil
        }
    }
}

// MARK: - Display Mode Enum
enum DisplayMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { self.rawValue }
}
