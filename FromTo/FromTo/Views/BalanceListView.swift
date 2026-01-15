//
//  BalanceListView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct BalanceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Balance.transactionDate, order: .reverse) private var balances: [Balance]

    let tab: AppTab

    var body: some View {
        NavigationStack {
            List {
                ForEach(balances) { balance in
                    NavigationLink {
                        BalanceDetailView(balance: balance, tab: tab)
                    } label: {
                        BalanceRowView(balance: balance)
                    }
                }
            }
            .navigationTitle("Balance")
            .overlay {
                if balances.isEmpty {
                    ContentUnavailableView {
                        Label("No Balance Records", systemImage: "list.bullet.clipboard")
                    } description: {
                        Text("Balance records are automatically created when you create investments")
                    }
                }
            }
            .tint(tab.color())
        }
    }
}

struct BalanceRowView: View {
    let balance: Balance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !balance.ticker.isEmpty {
                    Text(balance.ticker)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text(balance.name ?? "Untitled")
                    .font(balance.ticker.isEmpty ? .headline : .subheadline)
                    .foregroundColor(balance.ticker.isEmpty ? .primary : .secondary)
                Spacer()
                Text(balance.transactionType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(balance.transactionType.backgroundColor)
                    .foregroundColor(balance.transactionType.color)
                    .cornerRadius(8)
            }

            HStack {
                Text(balance.bankBrokerName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text("\(balance.numberOfStocks) stocks @ \(balance.stockPrice.formatted(fractionDigits: 2))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(balance.amount.formatted(fractionDigits: 2))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(balance.amount < 0 ? .red : .green)
            }

            HStack {
                Text("Transaction Cost: \(balance.transactionCost.formatted(fractionDigits: 2))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text(balance.transactionDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BalanceListView(tab: .balance)
}
