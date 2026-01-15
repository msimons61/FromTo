//
//  BankBrokerCostRowView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI

struct BankBrokerCostRowView: View {
    let provider: BankBrokerCost
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(provider.bankBrokerName.isEmpty ? "Untitled Provider" : provider.bankBrokerName)
                    .font(.headline)
                Spacer()
                if isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                } else {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            HStack {
                Text("Fixed: \(provider.fixedCost.formatted(fractionDigits: 2))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("Variable: \((provider.variableCostRate * 100).formatted(fractionDigits: 2))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text(provider.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let endDate = provider.endDate {
                    Text("→")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(endDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("→ Ongoing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
