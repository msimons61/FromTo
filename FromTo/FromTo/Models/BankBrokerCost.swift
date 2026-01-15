//
//  BankBrokerCost.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftData

@Model
final class BankBrokerCost {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // Identity
    var bankBrokerName: String = ""
    var startDate: Date = Date()
    var endDate: Date? = nil

    // Cost Structure (stored as Strings for Decimal precision)
    private var fixedCostString: String = "0"
    private var variableCostRateString: String = "0"
    private var maximumCostString: String = "0"

    init(
        bankBrokerName: String = "",
        startDate: Date = Date(),
        endDate: Date? = nil,
        fixedCost: Decimal = 0,
        variableCostRate: Decimal = 0,
        maximumCost: Decimal = 0
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.bankBrokerName = bankBrokerName
        self.startDate = startDate
        self.endDate = endDate
        self.fixedCostString = "\(fixedCost)"
        self.variableCostRateString = "\(variableCostRate)"
        self.maximumCostString = "\(maximumCost)"
    }
}

// MARK: - Decimal Properties (Translation Layer)
extension BankBrokerCost {
    /// Fixed cost as Decimal with perfect precision
    var fixedCost: Decimal {
        get { Decimal(string: fixedCostString) ?? 0 }
        set {
            fixedCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Variable cost rate as Decimal with perfect precision (percentage)
    var variableCostRate: Decimal {
        get { Decimal(string: variableCostRateString) ?? 0 }
        set {
            variableCostRateString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Maximum cost as Decimal with perfect precision
    var maximumCost: Decimal {
        get { Decimal(string: maximumCostString) ?? 0 }
        set {
            maximumCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }
}

// MARK: - Validation & Computed Properties
extension BankBrokerCost {
    /// Validates that the provider cost data is valid
    var isValid: Bool {
        guard !bankBrokerName.isEmpty else { return false }
        guard fixedCost >= 0, variableCostRate >= 0, maximumCost >= 0 else { return false }

        if let end = endDate {
            return startDate <= end
        }
        return true
    }

    /// Check if this provider's costs are active on a given date
    func isActive(on date: Date) -> Bool {
        if let end = endDate {
            return date >= startDate && date <= end
        }
        // If no end date, active from start date onwards
        return date >= startDate
    }

    /// Returns a list of validation errors
    var validationErrors: [String] {
        var errors: [String] = []

        if bankBrokerName.isEmpty {
            errors.append("Bank/Broker name is required")
        }

        if fixedCost < 0 {
            errors.append("Fixed cost must be >= 0")
        }

        if variableCostRate < 0 {
            errors.append("Variable cost rate must be >= 0")
        }

        if maximumCost < 0 {
            errors.append("Maximum cost must be >= 0")
        }

        if let end = endDate, startDate > end {
            errors.append("Start date must be before or equal to end date")
        }

        return errors
    }
}
