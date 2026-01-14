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
    @StateObject private var settings = SettingsData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.colorScheme)
                .task {
                    await performMigrations()
                }
        }
        .modelContainer(SwiftDataService.shared.modelContainer)
    }

    private func performMigrations() async {
        let hasMigrated = UserDefaults.standard.bool(forKey: "com.fromto.hasMigratedToCloud")

        guard !hasMigrated else {
            print("Cloud migration already completed")
            return
        }

        // Migrate Investment data to SwiftData
        do {
            try await SwiftDataService.shared.migrateFromUserDefaults()
        } catch {
            print("Failed to migrate investment data: \(error)")
        }

        // Migrate Settings to iCloud KVS
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
