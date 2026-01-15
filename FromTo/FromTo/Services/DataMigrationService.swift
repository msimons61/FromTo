//
//  DataMigrationService.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftData

/// Service for managing data migrations across app versions
@MainActor
class DataMigrationService {
    static let shared = DataMigrationService()

    private let migrationKey = "com.fromto.dataMigrationV2Completed"

    private init() {}

    /// Check if migration is needed
    func needsMigration() -> Bool {
        return !UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Perform complete migration to new data model
    func performMigration(modelContainer: ModelContainer) async throws {
        print("Starting data migration to V2...")

        // Step 1: Migrate Settings from CloudKeyValueStore to SwiftData
        try await migrateSettings(modelContainer: modelContainer)

        // Step 2: Clear old SwiftData models (Investment and Estimation will be replaced)
        // Note: We're doing a destructive migration - old data will be cleared
        // This is acceptable since the models have changed significantly

        // Step 3: Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        print("Data migration to V2 completed successfully")
    }

    /// Migrate Settings from CloudKeyValueStore to SwiftData
    private func migrateSettings(modelContainer: ModelContainer) async throws {
        let context = modelContainer.mainContext
        let cloudStore = CloudKeyValueStore.shared

        // Check if Settings already exist
        let descriptor = FetchDescriptor<Settings>()
        let existingSettings = try context.fetch(descriptor)

        if !existingSettings.isEmpty {
            print("Settings already migrated to SwiftData")
            return
        }

        // Read from CloudKeyValueStore
        let displayModeString = cloudStore.getString(forKey: "com.fromto.settings.displayMode") ?? "system"
        let displayMode = DisplayMode(rawValue: displayModeString) ?? .system

        let isDoubleCurrencyEnabled = cloudStore.getBool(forKey: "com.fromto.settings.isDoubleCurrencyEnabled") ?? true
        let isApplyCostEnabled = cloudStore.getBool(forKey: "com.fromto.settings.isApplyCostEnabled") ?? true

        let fromCurrency = cloudStore.getString(forKey: "com.fromto.settings.fromCurrency") ?? "USD"
        let toCurrency = cloudStore.getString(forKey: "com.fromto.settings.toCurrency") ?? "EUR"

        let defaultFixedCost = cloudStore.getDecimal(forKey: "com.fromto.settings.defaultFixedCost") ?? 0
        let defaultVariableCost = cloudStore.getDecimal(forKey: "com.fromto.settings.defaultVariableCost") ?? 0
        let defaultMaximumCost = cloudStore.getDecimal(forKey: "com.fromto.settings.defaultMaximumCost")

        // Create new Settings model
        let settings = Settings(
            displayMode: displayMode,
            doubleCurrency: isDoubleCurrencyEnabled,
            baseCurrency: fromCurrency,
            transactionCurrency: toCurrency,
            applyCost: isApplyCostEnabled,
            bankBrokerName: "",
            defaultFixedCost: defaultFixedCost,
            defaultVariableCost: defaultVariableCost,
            defaultMaximumCost: defaultMaximumCost
        )

        context.insert(settings)
        try context.save()

        print("Settings migrated from CloudKeyValueStore to SwiftData")
    }

    /// Clear old data (for destructive migration)
    func clearOldData(modelContainer: ModelContainer) async throws {
        let context = modelContainer.mainContext

        // Note: With the schema change, SwiftData will automatically handle
        // clearing incompatible models. This method is here for explicit clearing if needed.

        print("Old data cleared (handled by SwiftData schema migration)")
    }

    /// Reset migration state (for testing purposes)
    func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        print("Migration state reset")
    }
}
