//
//  SwiftDataService.swift
//  FromTo
//
//  Created by Claude Code on 14-01-2026.
//

import Foundation
import SwiftData
import CloudKit

/// Singleton service for managing SwiftData ModelContainer with CloudKit integration
@MainActor
class SwiftDataService {
    static let shared = SwiftDataService()

    let modelContainer: ModelContainer

    private init() {
        let schema = Schema([
            Investment.self,
            Projection.self,
            Settings.self,
            BankBrokerProvider.self,
            CostComponent.self,
            Balance.self
        ])

        do {
            // Try to create with CloudKit first with migration options
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.ms61consultancy.FromTo")
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            print("Successfully created ModelContainer with CloudKit")
        } catch {
            // If CloudKit fails, fall back to local-only storage
            print("CloudKit ModelContainer failed: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                print("Error userInfo: \(nsError.userInfo)")
            }
            print("Falling back to local-only storage")

            do {
                let localConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false
                )

                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [localConfiguration]
                )
                print("Successfully created local-only ModelContainer")
            } catch {
                print("Local ModelContainer also failed: \(error)")
                print("Error details: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("Error domain: \(nsError.domain)")
                    print("Error code: \(nsError.code)")
                    print("Error userInfo: \(nsError.userInfo)")
                }

                // Try one more time with in-memory storage for debugging
                print("Attempting in-memory storage as last resort...")
                do {
                    let memoryConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true
                    )

                    modelContainer = try ModelContainer(
                        for: schema,
                        configurations: [memoryConfiguration]
                    )
                    print("WARNING: Using in-memory storage - data will not persist!")
                } catch {
                    print("Even in-memory storage failed: \(error)")
                    fatalError("Could not create ModelContainer: \(error)\n\nThis usually means the schema has changed incompatibly. Try deleting the app and reinstalling.")
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Get or create the singleton Settings instance
    func getOrCreateSettings() throws -> Settings {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Settings>()

        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        // Create default settings
        let settings = Settings()
        context.insert(settings)
        try context.save()
        return settings
    }
}
