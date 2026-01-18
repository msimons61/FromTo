//
//  CostComponentRowView.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import SwiftUI

struct CostComponentRowView: View {
    let component: CostComponent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Component name
                Text(component.displayName)
                    .font(.headline)

                Spacer()

                // Type badge
                Text(component.componentType.defaultName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(component.isCredit ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(component.isCredit ? .green : .blue)
                    .cornerRadius(8)
            }

            // Calculation method
            Text(component.calculationMethod.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Cost summary
            HStack(spacing: 12) {
                if component.calculationMethod.usesFixed && component.fixedAmount > 0 {
                    Label(formatDecimal(component.fixedAmount), systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if component.calculationMethod.usesPercentage && component.percentageRate > 0 {
                    Label(formatPercentage(component.percentageRate), systemImage: "percent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if component.calculationMethod.usesMinMax {
                    if component.minimumAmount > 0 {
                        Label("Min: \(formatDecimal(component.minimumAmount))", systemImage: "arrow.down.to.line")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if component.maximumAmount > 0 {
                        Label("Max: \(formatDecimal(component.maximumAmount))", systemImage: "arrow.up.to.line")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Refundable indicator
            if component.isRefundable {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refundable: \(formatDecimal(component.creditAmount))")
                }
                .font(.caption)
                .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSNumber) ?? "\(value)"
    }

    private func formatPercentage(_ value: Decimal) -> String {
        let percentage = value * 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return (formatter.string(from: percentage as NSNumber) ?? "\(percentage)") + "%"
    }
}
