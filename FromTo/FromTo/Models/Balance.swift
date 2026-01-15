//
//  Balance.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftData

@Model
final class Balance {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()
    var transactionDate: Date = Date()
    private var transactionTypeString: String = "Buy"
    var bankBrokerName: String = ""
    var ticker: String = ""
    var name: String? = nil
    var numberOfStocks: Int = 0

    // Stored properties as String (perfect Decimal precision)
    private var stockPriceString: String = "0"
    private var transactionCostString: String = "0"

    // Relationship to Investment
    var investment: Investment?

    init(
        transactionDate: Date = Date(),
        transactionType: TransactionType = .buy,
        bankBrokerName: String = "",
        ticker: String = "",
        name: String? = nil,
        numberOfStocks: Int = 0,
        stockPrice: Decimal = 0,
        transactionCost: Decimal = 0,
        investment: Investment? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.transactionDate = transactionDate
        self.transactionTypeString = transactionType.rawValue
        self.bankBrokerName = bankBrokerName
        self.ticker = ticker
        self.name = name
        self.numberOfStocks = numberOfStocks
        self.stockPriceString = "\(stockPrice)"
        self.transactionCostString = "\(transactionCost)"
        self.investment = investment
    }
}

// MARK: - Properties
extension Balance {
    /// Transaction type (buy or sell)
    var transactionType: TransactionType {
        get { TransactionType(rawValue: transactionTypeString) ?? .buy }
        set {
            transactionTypeString = newValue.rawValue
            modifiedAt = Date()
        }
    }

    /// Stock price as Decimal with perfect precision
    var stockPrice: Decimal {
        get { Decimal(string: stockPriceString) ?? 0 }
        set {
            stockPriceString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Transaction cost (total cost in base currency) as Decimal with perfect precision
    var transactionCost: Decimal {
        get { Decimal(string: transactionCostString) ?? 0 }
        set {
            transactionCostString = "\(newValue)"
            modifiedAt = Date()
        }
    }

    /// Amount = (numberOfStocks × stockPrice) × (buy/withdrawal ? -1 : 1)
    /// Negative for buy/withdrawal (money out), positive for sell/deposit (money in)
    var amount: Decimal {
        let baseAmount = Decimal(numberOfStocks) * stockPrice
        switch transactionType {
        case .buy, .withdrawal:
            return -baseAmount
        case .sell, .deposit:
            return baseAmount
        }
    }
}

// MARK: - Factory Method
extension Balance {
    /// Creates a Balance from an Investment
    static func from(_ investment: Investment) -> Balance {
        return Balance(
            transactionDate: investment.transactionDate,
            transactionType: investment.transactionType,
            bankBrokerName: investment.bankBrokerName,
            ticker: investment.ticker,
            name: investment.name,
            numberOfStocks: investment.numberOfStocks,
            stockPrice: investment.stockPrice,
            transactionCost: investment.totalCost,
            investment: investment
        )
    }
}
