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
            BankBrokerCost.self
        ])

        do {
            // Try to create with CloudKit first
            let modelConfiguration = ModelConfiguration(
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
            print("Falling back to local-only storage")

            do {
                modelContainer = try ModelContainer(
                    for: Investment.self,
                    Projection.self,
                    Settings.self,
                    BankBrokerCost.self
                )
                print("Successfully created local-only ModelContainer")
            } catch {
                print("Local ModelContainer also failed: \(error)")
                fatalError("Could not create ModelContainer even without CloudKit: \(error)")
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
