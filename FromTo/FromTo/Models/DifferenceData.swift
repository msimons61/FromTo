//
//  DifferenceData.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation

struct DifferenceData {
    var fromValue: Decimal
    var toValue: Decimal

    init(fromValue: Decimal = 0, toValue: Decimal = 0) {
        self.fromValue = fromValue
        self.toValue = toValue
    }
}
