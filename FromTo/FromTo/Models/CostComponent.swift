//
//  CostComponent.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import Foundation
import SwiftData

@Model
final class CostComponent {
    // MARK: - Stored Properties

    var id: UUID = UUID()
    var componentType: ComponentType = ComponentType.transactionCommission
    var calculationMethod: CalculationMethod = CalculationMethod.fixedOnly
    var displayName: String = ""
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // String-based Decimal storage for cost parameters
    private var fixedAmountString: String = "0"
    private var percentageRateString: String = "0"
    private var minimumAmountString: String = "0"
    private var maximumAmountString: String = "0"

    // Refund/Credit properties
    var isRefundable: Bool = false
    private var creditAmountString: String = "0"
    var creditValidDays: Int = 0

    // MARK: - Relationships

    var provider: BankBrokerProvider? = nil

    // MARK: - Computed Properties

    var fixedAmount: Decimal {
        get { Decimal(string: fixedAmountString) ?? 0 }
        set {
            fixedAmountString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var percentageRate: Decimal {
        get { Decimal(string: percentageRateString) ?? 0 }
        set {
            percentageRateString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var minimumAmount: Decimal {
        get { Decimal(string: minimumAmountString) ?? 0 }
        set {
            minimumAmountString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var maximumAmount: Decimal {
        get { Decimal(string: maximumAmountString) ?? 0 }
        set {
            maximumAmountString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var creditAmount: Decimal {
        get { Decimal(string: creditAmountString) ?? 0 }
        set {
            creditAmountString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    var validationErrors: [String] {
        var errors: [String] = []

        if displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Component name is required")
        }

        // Check that at least one cost parameter is set based on calculation method
        switch calculationMethod {
        case .fixedOnly:
            if fixedAmount <= 0 {
                errors.append("Fixed amount must be greater than 0")
            }
        case .percentageOnly:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
        case .fixedPlusPercentage:
            if fixedAmount <= 0 && percentageRate <= 0 {
                errors.append("Either fixed amount or percentage rate must be greater than 0")
            }
        case .percentageWithMinMax:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
            if minimumAmount <= 0 {
                errors.append("Minimum amount must be greater than 0")
            }
        case .monthlyPercentageOfPortfolio:
            if percentageRate <= 0 {
                errors.append("Percentage rate must be greater than 0")
            }
        }

        if isRefundable && creditAmount <= 0 {
            errors.append("Credit amount must be greater than 0 for refundable components")
        }

        return errors
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        componentType: ComponentType = .transactionCommission,
        calculationMethod: CalculationMethod = .fixedOnly,
        displayName: String = "",
        fixedAmount: Decimal = 0,
        percentageRate: Decimal = 0,
        minimumAmount: Decimal = 0,
        maximumAmount: Decimal = 0,
        isRefundable: Bool = false,
        creditAmount: Decimal = 0,
        creditValidDays: Int = 0
    ) {
        self.id = id
        self.componentType = componentType
        self.calculationMethod = calculationMethod
        self.displayName = displayName.isEmpty ? componentType.defaultName : displayName
        self.fixedAmountString = "\(fixedAmount)"
        self.percentageRateString = "\(percentageRate)"
        self.minimumAmountString = "\(minimumAmount)"
        self.maximumAmountString = "\(maximumAmount)"
        self.isRefundable = isRefundable
        self.creditAmountString = "\(creditAmount)"
        self.creditValidDays = creditValidDays
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // MARK: - Cost Calculation

    /// Calculate the cost for a given transaction amount
    /// - Parameter transactionAmount: The transaction amount to calculate cost for
    /// - Returns: The calculated cost after applying constraints
    func calculateCost(transactionAmount: Decimal) -> Decimal {
        let baseCost: Decimal

        switch calculationMethod {
        case .fixedOnly:
            baseCost = fixedAmount

        case .percentageOnly:
            baseCost = transactionAmount * percentageRate

        case .fixedPlusPercentage:
            baseCost = fixedAmount + (transactionAmount * percentageRate)

        case .percentageWithMinMax:
            baseCost = transactionAmount * percentageRate

        case .monthlyPercentageOfPortfolio:
            // For portfolio-based fees, transactionAmount represents portfolio value
            baseCost = transactionAmount * percentageRate
        }

        return applyConstraints(baseCost)
    }

    /// Apply minimum and maximum constraints to the calculated cost
    /// - Parameter cost: The base calculated cost
    /// - Returns: The cost after applying min/max constraints
    private func applyConstraints(_ cost: Decimal) -> Decimal {
        var result = cost

        // Apply minimum constraint if set
        if minimumAmount > 0 {
            result = max(result, minimumAmount)
        }

        // Apply maximum constraint if set
        if maximumAmount > 0 {
            result = min(result, maximumAmount)
        }

        return result
    }

    /// Determine if this component represents a cost or a credit
    var isCredit: Bool {
        componentType.isCredit || isRefundable
    }
}
