//
//  CostCalculationService.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import Foundation

// MARK: - Cost Breakdown Structures

/// Breakdown of cost calculation for a single component
struct ComponentCostBreakdown {
    let component: CostComponent
    let calculatedAmount: Decimal
    let isCredit: Bool

    var displayName: String {
        component.displayName
    }

    var componentType: ComponentType {
        component.componentType
    }
}

/// Result of complete cost calculation for a provider
struct CostCalculationResult {
    let totalCost: Decimal
    let componentBreakdown: [ComponentCostBreakdown]
    let appliedCredits: Decimal
    let netCost: Decimal

    var hasCosts: Bool {
        totalCost > 0
    }

    var hasCredits: Bool {
        appliedCredits > 0
    }
}

// MARK: - Cost Calculation Service

/// Service for calculating costs based on provider components
class CostCalculationService {
    static let shared = CostCalculationService()

    private init() {}

    /// Calculate the total cost for a transaction based on provider components
    /// - Parameters:
    ///   - provider: The bank/broker provider with cost components
    ///   - transactionAmount: The amount of the transaction
    ///   - baseCurrency: The user's base currency
    ///   - transactionCurrency: The currency of the transaction
    ///   - currencyRate: The exchange rate between currencies
    /// - Returns: Complete cost calculation result with breakdown
    func calculateCost(
        provider: BankBrokerProvider,
        transactionAmount: Decimal,
        baseCurrency: String,
        transactionCurrency: String,
        currencyRate: Decimal
    ) -> CostCalculationResult {
        // Determine calculation amount based on provider's currency basis
        let calculationAmount: Decimal
        switch provider.calculationCurrency {
        case .transaction:
            calculationAmount = transactionAmount
        case .base:
            // Convert transaction amount to base currency
            calculationAmount = transactionAmount * currencyRate
        }

        // Calculate cost for each component
        var costs: [ComponentCostBreakdown] = []
        var credits: [ComponentCostBreakdown] = []

        for component in provider.costComponents ?? [] {
            let calculatedAmount = component.calculateCost(transactionAmount: calculationAmount)
            let breakdown = ComponentCostBreakdown(
                component: component,
                calculatedAmount: calculatedAmount,
                isCredit: component.isCredit
            )

            if component.isCredit {
                credits.append(breakdown)
            } else {
                costs.append(breakdown)
            }
        }

        // Calculate totals
        let totalCost = costs.reduce(0) { $0 + $1.calculatedAmount }
        let totalCredits = credits.reduce(0) { $0 + $1.calculatedAmount }

        // Apply legacy minimum of 150 to total cost (as per plan requirement)
        let adjustedCost = max(totalCost, 150)

        // Calculate net cost (cost minus credits, minimum 0)
        let netCost = max(0, adjustedCost - totalCredits)

        // Combine all breakdowns
        let allBreakdowns = costs + credits

        return CostCalculationResult(
            totalCost: adjustedCost,
            componentBreakdown: allBreakdowns,
            appliedCredits: totalCredits,
            netCost: netCost
        )
    }

    /// Calculate cost for portfolio-based fees (monthly service fees)
    /// - Parameters:
    ///   - provider: The bank/broker provider
    ///   - portfolioValue: Total portfolio value
    /// - Returns: Cost calculation result for portfolio fees
    func calculatePortfolioFees(
        provider: BankBrokerProvider,
        portfolioValue: Decimal
    ) -> CostCalculationResult {
        // Filter to only portfolio-based fee components
        let portfolioComponents = (provider.costComponents ?? []).filter {
            $0.calculationMethod == .monthlyPercentageOfPortfolio
        }

        var costs: [ComponentCostBreakdown] = []
        var credits: [ComponentCostBreakdown] = []

        for component in portfolioComponents {
            let calculatedAmount = component.calculateCost(transactionAmount: portfolioValue)
            let breakdown = ComponentCostBreakdown(
                component: component,
                calculatedAmount: calculatedAmount,
                isCredit: component.isCredit
            )

            if component.isCredit {
                credits.append(breakdown)
            } else {
                costs.append(breakdown)
            }
        }

        let totalCost = costs.reduce(0) { $0 + $1.calculatedAmount }
        let totalCredits = credits.reduce(0) { $0 + $1.calculatedAmount }
        let netCost = max(0, totalCost - totalCredits)

        let allBreakdowns = costs + credits

        return CostCalculationResult(
            totalCost: totalCost,
            componentBreakdown: allBreakdowns,
            appliedCredits: totalCredits,
            netCost: netCost
        )
    }

    /// Format a cost amount for display
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currency: The currency code
    /// - Returns: Formatted string
    func formatCost(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: amount as NSNumber) ?? "\(amount)"
    }
}
