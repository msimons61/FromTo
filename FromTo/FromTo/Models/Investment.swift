//
//  Investment.swift
//  FromTo
//
//  Created by Claude Code on 14-01-2026.
//

import Foundation
import SwiftData

@Model
final class Investment {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var transactionDate: Date = Date()
    var name: String?

    // Stored properties as String (perfect Decimal precision)
    private var availableAmountString: String = "0"
    private var stockPriceString: String = "0"
    private var currencyRateString: String = "1.0"
    private var fixedCostString: String = "0"
    private var variableCostString: String = "0"
    private var maximumCostString: String?

    init(
        availableAmount: Decimal = 0,
        stockPrice: Decimal = 0,
        currencyRate: Decimal = 1.0,
        fixedCost: Decimal = 0,
        variableCost: Decimal = 0,
        maximumCost: Decimal? = nil,
        name: String? = nil,
        transactionDate: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.transactionDate = transactionDate
        self.name = name

        // Store Decimals as Strings for perfect precision
        self.availableAmountString = "\(availableAmount)"
        self.stockPriceString = "\(stockPrice)"
        self.currencyRateString = "\(currencyRate)"
        self.fixedCostString = "\(fixedCost)"
        self.variableCostString = "\(variableCost)"
        self.maximumCostString = maximumCost.map { "\($0)" }
    }
}

// MARK: - Decimal Properties (Translation Layer)
extension Investment {
    /// Available amount as Decimal with perfect precision
    var availableAmount: Decimal {
        get { Decimal(string: availableAmountString) ?? 0 }
        set { availableAmountString = "\(newValue)" }
    }

    /// Stock price as Decimal with perfect precision
    var stockPrice: Decimal {
        get { Decimal(string: stockPriceString) ?? 0 }
        set { stockPriceString = "\(newValue)" }
    }

    /// Currency rate as Decimal with perfect precision
    var currencyRate: Decimal {
        get { Decimal(string: currencyRateString) ?? 1.0 }
        set { currencyRateString = "\(newValue)" }
    }

    /// Fixed cost as Decimal with perfect precision
    var fixedCost: Decimal {
        get { Decimal(string: fixedCostString) ?? 0 }
        set { fixedCostString = "\(newValue)" }
    }

    /// Variable cost as Decimal with perfect precision
    var variableCost: Decimal {
        get { Decimal(string: variableCostString) ?? 0 }
        set { variableCostString = "\(newValue)" }
    }

    /// Maximum cost as Decimal with perfect precision
    var maximumCost: Decimal? {
        get {
            guard let string = maximumCostString else { return nil }
            return Decimal(string: string)
        }
        set {
            maximumCostString = newValue.map { "\($0)" }
        }
    }
}

// MARK: - Computed Properties
extension Investment {
    /// Total cost including fixed and variable costs, capped by maximum if set
    var totalCost: Decimal {
        let variableCostAmount = availableAmount * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        if let maxCost = maximumCost, maxCost > 0 {
            return min(totalWithoutMax, maxCost)
        }
        return totalWithoutMax
    }

    /// Amount available for investment after costs, converted to target currency
    var investableAmount: Decimal {
        let netAmount = availableAmount - totalCost
        return currencyRate != 0 ? netAmount / currencyRate : 0
    }

    /// Number of whole stocks that can be purchased
    var numberOfStocks: Int {
        guard stockPrice > 0 else { return 0 }

        let stocks = investableAmount / stockPrice

        // Use Decimal's built-in rounding to floor
        var stocksValue = stocks
        var rounded = Decimal()
        NSDecimalRound(&rounded, &stocksValue, 0, .down)

        return Int(truncating: rounded as NSNumber)
    }

    /// Total amount invested (number of stocks × stock price)
    var investedAmount: Decimal {
        return Decimal(numberOfStocks) * stockPrice
    }

    /// Remaining amount after purchasing stocks
    var remainingAmount: Decimal {
        return investableAmount - investedAmount
    }
}
