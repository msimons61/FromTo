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
    var providerId: UUID? = nil
    var providerName: String? = nil
    private var transactionTypeString: String = "Buy"

    // Relationship to Balance (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \Balance.investment)
    var balance: Balance?

    // Stored properties as String (perfect Decimal precision)
    private var stockPriceString: String = "0"
    private var currencyRateString: String = "1.0"

    init(
        numberOfStocks: Int = 0,
        stockPrice: Decimal = 0,
        ticker: String = "",
        currencyRate: Decimal = 1.0,
        name: String? = nil,
        baseCurrency: String = "USD",
        transactionCurrency: String = "EUR",
        providerId: UUID? = nil,
        providerName: String? = nil,
        transactionDate: Date = Date(),
        transactionType: TransactionType = .buy
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
        self.providerId = providerId
        self.providerName = providerName
        self.transactionTypeString = transactionType.rawValue

        // Store Decimals as Strings for perfect precision
        self.stockPriceString = "\(stockPrice)"
        self.currencyRateString = "\(currencyRate)"
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

    /// Transaction type (buy or sell)
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeString) ?? .buy }
        set {
            transactionTypeString = newValue.rawValue
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

    /// Total cost - returns 150 as legacy minimum
    /// Note: Investment stores a snapshot at transaction time, not dynamic calculation
    var totalCost: Decimal {
        return 150 // Legacy minimum for historical records
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
            name: projection.name,
            baseCurrency: projection.baseCurrency,
            transactionCurrency: projection.transactionCurrency,
            providerId: projection.providerId,
            providerName: projection.providerName,
            transactionDate: projection.transactionDate,
            transactionType: projection.transactionType
        )
    }
}
