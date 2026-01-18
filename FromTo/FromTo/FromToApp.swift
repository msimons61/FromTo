//
//  FromToApp.swift
//  FromTo
//
//  Created by Marlon Simons on 12-01-2026.
//

import SwiftUI
import SwiftData

@main
struct FromToApp: App {
    @StateObject private var legacySettings = SettingsData() // Keep for migration purposes
    @StateObject private var settingsObserver: SettingsObserver
    @State private var showCurrencyUpdateAlert = false

    init() {
        // Initialize SettingsObserver with ModelContainer
        let observer = SettingsObserver(modelContainer: SwiftDataService.shared.modelContainer)
        _settingsObserver = StateObject(wrappedValue: observer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(settingsObserver.colorScheme)
                .task {
                    await performMigrations()
                    await updateCurrencyListIfNeeded()
                }
                .alert("Currency Update Taking Longer Than Expected", isPresented: $showCurrencyUpdateAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("The currency list update is taking longer than 10 seconds. This may indicate a network issue. The app will continue to use the cached list.")
                }
        }
        .modelContainer(SwiftDataService.shared.modelContainer)
    }

    private func performMigrations() async {
        // V2 Migration: New data model
        let migrationService = DataMigrationService.shared
        if migrationService.needsMigration() {
            do {
                try await migrationService.performMigration(
                    modelContainer: SwiftDataService.shared.modelContainer
                )
            } catch {
                print("Failed to perform V2 migration: \(error)")
            }
        }

        // V1 Migration: Cloud migration (legacy)
        let hasMigrated = UserDefaults.standard.bool(forKey: "com.fromto.hasMigratedToCloud")

        guard !hasMigrated else {
            print("Cloud migration already completed")
            return
        }

        // Migrate Settings to iCloud KVS (will be migrated to SwiftData by V2 migration)
        await legacySettings.performCloudMigration()

        // Migrate Difference calculator to iCloud KVS
        let cloudStore = CloudKeyValueStore.shared
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.fromValue")
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.toValue")
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.isRelativeMode")

        // Mark as migrated
        UserDefaults.standard.set(true, forKey: "com.fromto.hasMigratedToCloud")
        print("Cloud migration completed successfully")
    }

    @MainActor
    private func updateCurrencyListIfNeeded() async {
        let context = SwiftDataService.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Settings>()

        guard let settings = try? context.fetch(descriptor).first else {
            print("No settings found for currency update")
            return
        }

        // Check if refresh is needed (older than 24 hours)
        guard settings.needsCurrencyRefresh else {
            print("Currency list is up to date")
            return
        }

        print("Updating currency list from Frankfurter API...")

        // Create a timeout task that shows alert after 10 seconds
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            if !Task.isCancelled {
                await MainActor.run {
                    showCurrencyUpdateAlert = true
                    print("Currency update timeout - showing alert")
                }
            }
        }

        // Fetch currencies in background
        do {
            let currencies = try await CurrencyRateService.shared.fetchSupportedCurrencies()

            // Cancel timeout task if fetch succeeded
            timeoutTask.cancel()

            // Update cache
            settings.cachedSupportedCurrencies = currencies
            settings.lastCurrencyFetchDate = Date()
            try? context.save()

            print("Currency list updated successfully: \(currencies.count) currencies")
        } catch {
            // Cancel timeout task
            timeoutTask.cancel()

            print("Failed to update currency list: \(error.localizedDescription)")
            // App will continue using cached or static fallback list
        }
    }
}
