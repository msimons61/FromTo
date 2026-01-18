//
//  BankBrokerProvider.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import Foundation
import SwiftData

@Model
final class BankBrokerProvider {
    // MARK: - Stored Properties

    var id: UUID = UUID()
    var name: String = ""
    var accountTier: String = ""
    var startDate: Date = Date()
    var endDate: Date? = nil
    var calculationCurrency: CurrencyBasis = CurrencyBasis.transaction
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // String-based Decimal storage
    private var minimumBalanceForTierString: String = "0"
    private var startingBalanceString: String = "0"

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \CostComponent.provider)
    var costComponents: [CostComponent]?

    // MARK: - Computed Properties

    var minimumBalanceForTier: Decimal {
        get { Decimal(string: minimumBalanceForTierString) ?? 0 }
        set {
            minimumBalanceForTierString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var startingBalance: Decimal {
        get { Decimal(string: startingBalanceString) ?? 0 }
        set {
            startingBalanceString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var displayName: String {
        if accountTier.isEmpty {
            return name
        } else {
            return "\(name) - \(accountTier)"
        }
    }

    var hasComponents: Bool {
        !(costComponents?.isEmpty ?? true)
    }

    var validationErrors: [String] {
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Provider name is required")
        }

        if startingBalance <= 0 {
            errors.append("Starting balance must be greater than 0")
        }

        if costComponents?.isEmpty ?? true {
            errors.append("At least one cost component is required")
        }

        if let endDate = endDate, endDate <= startDate {
            errors.append("End date must be after start date")
        }

        return errors
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "",
        accountTier: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        calculationCurrency: CurrencyBasis = .transaction,
        minimumBalanceForTier: Decimal = 0,
        startingBalance: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.accountTier = accountTier
        self.startDate = startDate
        self.endDate = endDate
        self.calculationCurrency = calculationCurrency
        self.minimumBalanceForTierString = "\(minimumBalanceForTier)"
        self.startingBalanceString = "\(startingBalance)"
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // MARK: - Methods

    func isActive(on date: Date) -> Bool {
        if let endDate = endDate {
            return date >= startDate && date <= endDate
        } else {
            return date >= startDate
        }
    }

    func addComponent(_ component: CostComponent) {
        if costComponents == nil {
            costComponents = []
        }
        costComponents?.append(component)
        component.provider = self
        modifiedAt = Date()
    }

    func removeComponent(_ component: CostComponent) {
        costComponents?.removeAll { $0.id == component.id }
        modifiedAt = Date()
    }
}
