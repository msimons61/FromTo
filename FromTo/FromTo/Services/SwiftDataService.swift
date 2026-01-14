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
        let schema = Schema([Investment.self])

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
                modelContainer = try ModelContainer(for: Investment.self)
                print("Successfully created local-only ModelContainer")
            } catch {
                print("Local ModelContainer also failed: \(error)")
                fatalError("Could not create ModelContainer even without CloudKit: \(error)")
            }
        }
    }

    // MARK: - Migration

    /// Migrates existing UserDefaults investment data to SwiftData
    /// This is a one-time migration that runs on first launch
    func migrateFromUserDefaults() async throws {
        let context = modelContainer.mainContext

        // Check if migration already done by checking if any investments exist
        let descriptor = FetchDescriptor<Investment>()
        let existingInvestments = try context.fetch(descriptor)

        guard existingInvestments.isEmpty else {
            print("SwiftData migration already completed")
            return
        }

        // Attempt to load from UserDefaults
        let userDefaults = UserDefaults.standard

        guard let availableAmountStr = userDefaults.string(forKey: "com.fromto.investment.availableAmount"),
              let availableAmount = Decimal(string: availableAmountStr) else {
            print("No UserDefaults investment data to migrate")
            return
        }

        // Load other properties
        let stockPrice = userDefaults.string(forKey: "com.fromto.investment.stockPrice")
            .flatMap { Decimal(string: $0) } ?? 0
        let currencyRate = userDefaults.string(forKey: "com.fromto.investment.currencyRate")
            .flatMap { Decimal(string: $0) } ?? 1.0
        let fixedCost = userDefaults.string(forKey: "com.fromto.investment.fixedCost")
            .flatMap { Decimal(string: $0) } ?? 0
        let variableCost = userDefaults.string(forKey: "com.fromto.investment.variableCost")
            .flatMap { Decimal(string: $0) } ?? 0
        let maximumCost = userDefaults.string(forKey: "com.fromto.investment.maximumCost")
            .flatMap { Decimal(string: $0) }

        // Create migrated investment
        let migratedInvestment = Investment(
            availableAmount: availableAmount,
            stockPrice: stockPrice,
            currencyRate: currencyRate,
            fixedCost: fixedCost,
            variableCost: variableCost,
            maximumCost: maximumCost,
            name: "Migrated Calculation"
        )

        context.insert(migratedInvestment)
        try context.save()

        print("Successfully migrated investment from UserDefaults to SwiftData")
    }
}
