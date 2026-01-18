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
    private let componentArchitectureMigrationKey = "com.fromto.componentArchitectureMigrationCompleted"

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

        // Note: Old cost settings are ignored in the new provider-based architecture
        // Users will need to create providers and select them in settings

        // Create new Settings model
        let settings = Settings(
            displayMode: displayMode,
            doubleCurrency: isDoubleCurrencyEnabled,
            baseCurrency: fromCurrency,
            transactionCurrency: toCurrency,
            applyCost: isApplyCostEnabled,
            defaultProviderId: nil
        )

        context.insert(settings)
        try context.save()

        print("Settings migrated from CloudKeyValueStore to SwiftData")
    }

    /// Clear old data (for destructive migration)
    func clearOldData(modelContainer: ModelContainer) async throws {
        _ = modelContainer.mainContext

        // Note: With the schema change, SwiftData will automatically handle
        // clearing incompatible models. This method is here for explicit clearing if needed.

        print("Old data cleared (handled by SwiftData schema migration)")
    }

    /// Reset migration state (for testing purposes)
    func resetMigrationState() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
        UserDefaults.standard.removeObject(forKey: componentArchitectureMigrationKey)
        print("Migration state reset")
    }

    /// Migrate to component-based cost architecture
    /// Note: This is a destructive migration. BankBrokerCost has been removed from the schema,
    /// and SwiftData automatically handles removal of incompatible models.
    /// Users will need to create new BankBrokerProvider records.
    func migrateToComponentArchitecture(modelContainer: ModelContainer) async throws {
        // Check if migration already completed
        if UserDefaults.standard.bool(forKey: componentArchitectureMigrationKey) {
            print("Component architecture migration already completed")
            return
        }

        print("Starting component architecture migration...")

        // Since BankBrokerCost has been removed from the schema, SwiftData will automatically
        // delete any existing BankBrokerCost records. This is a destructive migration.

        // Users will need to recreate their cost providers using the new component architecture

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: componentArchitectureMigrationKey)
        print("Component architecture migration completed")
    }
}
