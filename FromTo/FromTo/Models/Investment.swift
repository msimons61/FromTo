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
    var numberOfStocks: Int = 0
    var name: String?
    var ticker: String = ""
    var baseCurrency: String = "USD"
    var transactionCurrency: String = "EUR"
    var bankBrokerName: String = ""
    var providerName: String? = nil

    // Stored properties as String (perfect Decimal precision)
    private var stockPriceString: String = "0"
    private var currencyRateString: String = "1.0"
    private var fixedCostString: String = "0"
    private var variableCostString: String = "0"
    private var maximumCostString: String = "0"

    init(
        numberOfStocks: Int = 0,
        stockPrice: Decimal = 0,
        ticker: String = "",
        currencyRate: Decimal = 1.0,
        fixedCost: Decimal = 0,
        variableCost: Decimal = 0,
        maximumCost: Decimal = 0,
        name: String? = nil,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
        bankBrokerName: String = "",
        providerName: String? = nil,
        transactionDate: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.transactionDate = transactionDate
        self.numberOfStocks = numberOfStocks
        self.name = name
        self.ticker = ticker
        self.baseCurrency = baseCurrency
        self.transactionCurrency = transactionCurrency
        self.bankBrokerName = bankBrokerName
        self.providerName = providerName

        // Store Decimals as Strings for perfect precision
        self.stockPriceString = "\(stockPrice)"
        self.currencyRateString = "\(currencyRate)"
        self.fixedCostString = "\(fixedCost)"
        self.variableCostString = "\(variableCost)"
        self.maximumCostString = "\(maximumCost)"
    }
}

// MARK: - Decimal Properties (Translation Layer)
extension Investment {
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
    var maximumCost: Decimal {
        get { Decimal(string: maximumCostString) ?? 0 }
        set {
            maximumCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }
}

// MARK: - Computed Properties
extension Investment {
    /// Total amount invested (number of stocks × stock price)
    var totalInvested: Decimal {
        return Decimal(numberOfStocks) * stockPrice
    }

    /// Total cost including fixed and variable costs, with minimum and maximum cap
    /// Formula: MAX(150, fixedCost + (totalInvested / currencyRate * variableCost))
    var totalCost: Decimal {
        // Variable cost applies to the invested amount in base currency
        let investedAmountBase = totalInvested / currencyRate
        let variableCostAmount = investedAmountBase * variableCost
        let totalWithoutMax = fixedCost + variableCostAmount

        // Apply minimum cost of 150
        let costWithMinimum = max(150, totalWithoutMax)

        // Apply maximum cost cap
        if maximumCost > 0 {
            return min(costWithMinimum, maximumCost)
        }
        return costWithMinimum
    }

    /// Total amount including investment and costs in transaction currency
    var totalAmount: Decimal {
        return totalInvested + totalCost
    }

    /// Total amount converted to base currency
    var totalAmountInBaseCurrency: Decimal {
        return totalAmount / currencyRate
    }
}

// MARK: - Factory Method
extension Investment {
    /// Creates an Investment from a Projection
    static func from(_ projection: Projection) -> Investment {
        return Investment(
            numberOfStocks: projection.actualNumberOfStocks,
            stockPrice: projection.stockPrice,
            ticker: projection.ticker,
            currencyRate: projection.currencyRate,
            fixedCost: projection.fixedCost,
            variableCost: projection.variableCost,
            maximumCost: projection.maximumCost ?? 0,
            name: projection.name,
            baseCurrency: projection.baseCurrency,
            transactionCurrency: projection.transactionCurrency,
            bankBrokerName: projection.bankBrokerName,
            providerName: projection.providerName,
            transactionDate: projection.transactionDate
        )
    }
}
