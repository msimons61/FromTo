//
//  InvestmentData.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation

struct InvestmentData {
    var availableAmount: Decimal
    var stockPrice: Decimal
    var fixedCost: Decimal
    var variableCost: Decimal
    var maximumCost: Decimal?

    init(
        availableAmount: Decimal = 0,
        stockPrice: Decimal = 0,
        fixedCost: Decimal = 0,
        variableCost: Decimal = 0,
        maximumCost: Decimal? = nil
    ) {
        self.availableAmount = availableAmount
        self.stockPrice = stockPrice
        self.fixedCost = fixedCost
        self.variableCost = variableCost
        self.maximumCost = maximumCost
    }
}
