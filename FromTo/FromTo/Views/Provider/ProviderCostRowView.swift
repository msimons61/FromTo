//
//  ProviderCostRowView.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import SwiftUI

struct ProviderCostRowView: View {
    let provider: BankBrokerProvider

    private var isActive: Bool {
        provider.isActive(on: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Active status indicator
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                // Provider name
                Text(provider.displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    // Component count
                    Label("\(provider.costComponents?.count ?? 0) components", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Calculation currency
                    Label(provider.calculationCurrency.displayName, systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Valid period for expired providers
                if !isActive, let endDate = provider.endDate {
                    Text("Expired \(endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}
