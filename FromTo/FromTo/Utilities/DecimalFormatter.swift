//
//  DecimalFormatter.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation

struct DecimalFormatterUtility {
    static let shared = DecimalFormatterUtility()

    // Format decimal for display with locale-specific separators
    func format(_ decimal: Decimal, fractionDigits: Int = 2, includeGrouping: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.usesGroupingSeparator = includeGrouping
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = 0

        return formatter.string(from: decimal as NSNumber) ?? "\(decimal)"
    }

    // Parse string to decimal with locale-aware parsing
    func parse(_ string: String) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current

        // Try parsing with current locale first
        if let number = formatter.number(from: string) {
            return number.decimalValue
        }

        // Fallback: try normalizing common separators
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let groupingSeparator = Locale.current.groupingSeparator ?? ","

        // Remove grouping separators and normalize decimal separator
        var normalized = string
            .replacingOccurrences(of: groupingSeparator, with: "")

        // If user typed wrong separator, try to fix it
        if decimalSeparator == "," {
            // European locale: swap dots for commas
            if normalized.contains(".") && !normalized.contains(",") {
                normalized = normalized.replacingOccurrences(of: ".", with: ",")
            }
        } else {
            // US locale: swap commas for dots
            if normalized.contains(",") && !normalized.contains(".") {
                normalized = normalized.replacingOccurrences(of: ",", with: ".")
            }
        }

        return formatter.number(from: normalized)?.decimalValue
    }

    // Generate locale-aware placeholder
    func placeholder(fractionDigits: Int = 2) -> String {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let groupingSeparator = Locale.current.groupingSeparator ?? ","

        if fractionDigits == 0 {
            return "0"
        }

        let fractionalPart = String(repeating: "0", count: fractionDigits)
        return "0\(decimalSeparator)\(fractionalPart)"
    }

    // Generate placeholder with thousand separator example
    func placeholderWithGrouping(fractionDigits: Int = 2) -> String {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        let groupingSeparator = Locale.current.groupingSeparator ?? ","

        if fractionDigits == 0 {
            return "1\(groupingSeparator)234"
        }

        let fractionalPart = String(repeating: "0", count: fractionDigits)
        return "1\(groupingSeparator)234\(decimalSeparator)\(fractionalPart)"
    }
}

// Extension for convenience
extension Decimal {
    func formatted(fractionDigits: Int = 2, includeGrouping: Bool = true) -> String {
        return DecimalFormatterUtility.shared.format(self, fractionDigits: fractionDigits, includeGrouping: includeGrouping)
    }
}

extension String {
    var decimalValue: Decimal? {
        return DecimalFormatterUtility.shared.parse(self)
    }
}
