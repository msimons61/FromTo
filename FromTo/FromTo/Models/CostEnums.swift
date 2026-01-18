//
//  CostEnums.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import Foundation

// MARK: - Component Type

/// Defines the type of cost component in a bank/broker fee structure
enum ComponentType: String, Codable, CaseIterable, Identifiable {
    case transactionCommission
    case serviceFee
    case currencyConversion
    case accountCredit
    case regulatoryFee
    case exchangeFee

    var id: String { rawValue }

    var defaultName: String {
        switch self {
        case .transactionCommission:
            return "Transaction Commission"
        case .serviceFee:
            return "Service Fee"
        case .currencyConversion:
            return "Currency Conversion Fee"
        case .accountCredit:
            return "Account Credit"
        case .regulatoryFee:
            return "Regulatory Fee"
        case .exchangeFee:
            return "Exchange Fee"
        }
    }

    var description: String {
        switch self {
        case .transactionCommission:
            return "Fee charged per transaction (buy/sell)"
        case .serviceFee:
            return "Periodic account maintenance fee"
        case .currencyConversion:
            return "Fee for converting between currencies"
        case .accountCredit:
            return "Credit or refund applied to account"
        case .regulatoryFee:
            return "Government or regulatory charges"
        case .exchangeFee:
            return "Fee charged by the exchange"
        }
    }

    var isCredit: Bool {
        self == .accountCredit
    }
}

// MARK: - Calculation Method

/// Defines how a cost component is calculated
enum CalculationMethod: String, Codable, CaseIterable, Identifiable {
    case fixedOnly
    case percentageOnly
    case fixedPlusPercentage
    case percentageWithMinMax
    case monthlyPercentageOfPortfolio

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fixedOnly:
            return "Fixed Amount"
        case .percentageOnly:
            return "Percentage Only"
        case .fixedPlusPercentage:
            return "Fixed + Percentage"
        case .percentageWithMinMax:
            return "Percentage with Min/Max"
        case .monthlyPercentageOfPortfolio:
            return "Monthly % of Portfolio"
        }
    }

    var description: String {
        switch self {
        case .fixedOnly:
            return "A fixed amount per transaction"
        case .percentageOnly:
            return "A percentage of the transaction amount"
        case .fixedPlusPercentage:
            return "A fixed amount plus a percentage of the transaction"
        case .percentageWithMinMax:
            return "A percentage with minimum and maximum limits"
        case .monthlyPercentageOfPortfolio:
            return "A monthly percentage of total portfolio value"
        }
    }

    var usesFixed: Bool {
        switch self {
        case .fixedOnly, .fixedPlusPercentage, .monthlyPercentageOfPortfolio:
            return true
        case .percentageOnly, .percentageWithMinMax:
            return false
        }
    }

    var usesPercentage: Bool {
        switch self {
        case .fixedOnly:
            return false
        case .percentageOnly, .fixedPlusPercentage, .percentageWithMinMax, .monthlyPercentageOfPortfolio:
            return true
        }
    }

    var usesMinMax: Bool {
        self == .percentageWithMinMax
    }
}

// MARK: - Currency Basis

/// Defines which currency is used as the basis for cost calculation
enum CurrencyBasis: String, Codable, CaseIterable, Identifiable {
    case transaction
    case base

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transaction:
            return "Transaction Currency"
        case .base:
            return "Base Currency"
        }
    }

    var description: String {
        switch self {
        case .transaction:
            return "Calculate costs in the currency of the transaction"
        case .base:
            return "Calculate costs in your base currency"
        }
    }
}
