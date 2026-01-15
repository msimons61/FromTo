//
//  TransactionType.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import Foundation
import SwiftUI

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case buy = "Buy"
    case sell = "Sell"
    case deposit = "Deposit"
    case withdrawal = "Withdrawal"

    var id: String { rawValue }

    /// Returns the color for this transaction type
    var color: Color {
        switch self {
        case .buy, .withdrawal:
            return .red
        case .sell, .deposit:
            return .green
        }
    }

    /// Returns the background color for this transaction type
    var backgroundColor: Color {
        switch self {
        case .buy, .withdrawal:
            return Color.red.opacity(0.2)
        case .sell, .deposit:
            return Color.green.opacity(0.2)
        }
    }
}
