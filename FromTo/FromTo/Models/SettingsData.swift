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

    @Published var fromCurrency: String {
        didSet {
            UserDefaults.standard.set(fromCurrency, forKey: "com.fromto.settings.fromCurrency")
        }
    }

    @Published var toCurrency: String {
        didSet {
            UserDefaults.standard.set(toCurrency, forKey: "com.fromto.settings.toCurrency")
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
}

// MARK: - Display Mode Enum
enum DisplayMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"

    var id: String { self.rawValue }
}
