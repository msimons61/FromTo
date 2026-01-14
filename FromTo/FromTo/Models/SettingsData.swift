//
//  SettingsData.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI
import Combine

@MainActor
class SettingsData: ObservableObject {
    // MARK: - Cloud Storage
    private let cloudStore = CloudKeyValueStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Keys
    private enum Keys {
        static let displayMode = "com.fromto.settings.displayMode"
        static let isDoubleCurrencyEnabled = "com.fromto.settings.isDoubleCurrencyEnabled"
        static let isApplyCostEnabled = "com.fromto.settings.isApplyCostEnabled"
        static let fromCurrency = "com.fromto.settings.fromCurrency"
        static let toCurrency = "com.fromto.settings.toCurrency"
        static let currencyRate = "com.fromto.settings.currencyRate"
        static let defaultFixedCost = "com.fromto.settings.defaultFixedCost"
        static let defaultVariableCost = "com.fromto.settings.defaultVariableCost"
        static let defaultMaximumCost = "com.fromto.settings.defaultMaximumCost"
    }

    // MARK: - Published Properties
    @Published var displayMode: DisplayMode {
        didSet {
            cloudStore.setString(displayMode.rawValue, forKey: Keys.displayMode)
        }
    }

    @Published var isDoubleCurrencyEnabled: Bool {
        didSet {
            cloudStore.setBool(isDoubleCurrencyEnabled, forKey: Keys.isDoubleCurrencyEnabled)
            syncCurrenciesIfNeeded()
        }
    }

    @Published var isApplyCostEnabled: Bool {
        didSet {
            cloudStore.setBool(isApplyCostEnabled, forKey: Keys.isApplyCostEnabled)
            resetCostsIfNeeded()
        }
    }

    @Published var fromCurrency: String {
        didSet {
            cloudStore.setString(fromCurrency, forKey: Keys.fromCurrency)
            updateCurrencyRateIfNeeded()
            syncCurrenciesIfNeeded()
        }
    }

    @Published var toCurrency: String {
        didSet {
            cloudStore.setString(toCurrency, forKey: Keys.toCurrency)
            updateCurrencyRateIfNeeded()
        }
    }

    @Published var currencyRate: Decimal {
        didSet {
            cloudStore.setDecimal(currencyRate, forKey: Keys.currencyRate)
        }
    }

    @Published var defaultFixedCost: Decimal {
        didSet {
            cloudStore.setDecimal(defaultFixedCost, forKey: Keys.defaultFixedCost)
        }
    }

    @Published var defaultVariableCost: Decimal {
        didSet {
            cloudStore.setDecimal(defaultVariableCost, forKey: Keys.defaultVariableCost)
        }
    }

    @Published var defaultMaximumCost: Decimal? {
        didSet {
            if let value = defaultMaximumCost {
                cloudStore.setDecimal(value, forKey: Keys.defaultMaximumCost)
            } else {
                cloudStore.remove(forKey: Keys.defaultMaximumCost)
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
        // Load from cloud storage (with UserDefaults fallback)
        if let savedMode = cloudStore.getString(forKey: Keys.displayMode),
           let mode = DisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        } else {
            self.displayMode = .system
        }

        // Use getBool which handles nil properly
        self.isDoubleCurrencyEnabled = cloudStore.getBool(forKey: Keys.isDoubleCurrencyEnabled) ?? true
        self.isApplyCostEnabled = cloudStore.getBool(forKey: Keys.isApplyCostEnabled) ?? true

        self.fromCurrency = cloudStore.getString(forKey: Keys.fromCurrency) ?? "USD"
        self.toCurrency = cloudStore.getString(forKey: Keys.toCurrency) ?? "EUR"

        self.currencyRate = cloudStore.getDecimal(forKey: Keys.currencyRate) ?? 1.0
        self.defaultFixedCost = cloudStore.getDecimal(forKey: Keys.defaultFixedCost) ?? 0
        self.defaultVariableCost = cloudStore.getDecimal(forKey: Keys.defaultVariableCost) ?? 0
        self.defaultMaximumCost = cloudStore.getDecimal(forKey: Keys.defaultMaximumCost)

        setupCloudObserver()
    }

    // MARK: - Cloud Sync
    private func setupCloudObserver() {
        NotificationCenter.default.publisher(
            for: .cloudKeyValueStoreDidUpdate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.reloadFromCloud()
        }
        .store(in: &cancellables)
    }

    private func reloadFromCloud() {
        // Reload all properties from cloud storage (without UserDefaults fallback)
        // This prevents overwriting cloud data with stale local data

        if let savedMode = cloudStore.getString(forKey: Keys.displayMode, fallbackToUserDefaults: false),
           let mode = DisplayMode(rawValue: savedMode) {
            displayMode = mode
        }

        if let value = cloudStore.getBool(forKey: Keys.isDoubleCurrencyEnabled, fallbackToUserDefaults: false) {
            isDoubleCurrencyEnabled = value
        }

        if let value = cloudStore.getBool(forKey: Keys.isApplyCostEnabled, fallbackToUserDefaults: false) {
            isApplyCostEnabled = value
        }

        if let value = cloudStore.getString(forKey: Keys.fromCurrency, fallbackToUserDefaults: false) {
            fromCurrency = value
        }

        if let value = cloudStore.getString(forKey: Keys.toCurrency, fallbackToUserDefaults: false) {
            toCurrency = value
        }

        if let value = cloudStore.getDecimal(forKey: Keys.currencyRate, fallbackToUserDefaults: false) {
            currencyRate = value
        }

        if let value = cloudStore.getDecimal(forKey: Keys.defaultFixedCost, fallbackToUserDefaults: false) {
            defaultFixedCost = value
        }

        if let value = cloudStore.getDecimal(forKey: Keys.defaultVariableCost, fallbackToUserDefaults: false) {
            defaultVariableCost = value
        }

        // For optional values, check explicitly
        defaultMaximumCost = cloudStore.getDecimal(forKey: Keys.defaultMaximumCost, fallbackToUserDefaults: false)
    }

    func performCloudMigration() async {
        // Migrate all keys from UserDefaults to iCloud KVS
        let keys = [
            Keys.displayMode,
            Keys.isDoubleCurrencyEnabled,
            Keys.isApplyCostEnabled,
            Keys.fromCurrency,
            Keys.toCurrency,
            Keys.currencyRate,
            Keys.defaultFixedCost,
            Keys.defaultVariableCost,
            Keys.defaultMaximumCost
        ]

        var migratedCount = 0
        for key in keys {
            if cloudStore.migrateFromUserDefaults(key: key) {
                migratedCount += 1
            }
        }

        if migratedCount > 0 {
            print("Migrated \(migratedCount) settings keys to iCloud KVS")
        } else {
            print("No settings migration needed")
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
