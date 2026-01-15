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
    @StateObject private var settings = SettingsData() // Keep for migration purposes

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(getColorScheme())
                .task {
                    await performMigrations()
                }
        }
        .modelContainer(SwiftDataService.shared.modelContainer)
    }

    @MainActor
    private func getColorScheme() -> ColorScheme? {
        let context = SwiftDataService.shared.modelContainer.mainContext
        let descriptor = FetchDescriptor<Settings>()
        guard let settings = try? context.fetch(descriptor).first else { return nil }
        return settings.colorScheme
    }

    private func performMigrations() async {
        // V2 Migration: New data model
        let migrationService = await DataMigrationService.shared
        if await migrationService.needsMigration() {
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
        await settings.performCloudMigration()

        // Migrate Difference calculator to iCloud KVS
        let cloudStore = CloudKeyValueStore.shared
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.fromValue")
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.toValue")
        _ = cloudStore.migrateFromUserDefaults(key: "com.fromto.difference.isRelativeMode")

        // Mark as migrated
        UserDefaults.standard.set(true, forKey: "com.fromto.hasMigratedToCloud")
        print("Cloud migration completed successfully")
    }
}
