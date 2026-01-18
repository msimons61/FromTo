//
//  BalanceDetailView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct BalanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let balance: Balance
    let tab: AppTab

    var body: some View {
        Form {
            // MARK: - Transaction Details Section
            Section {
                HStack {
                    Text("Transaction Date")
                    Spacer()
                    Text(balance.transactionDate.formatted(date: .long, time: .omitted))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Transaction Type")
                    Spacer()
                    Text(balance.transactionType.rawValue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(balance.transactionType.backgroundColor)
                        .foregroundColor(balance.transactionType.color)
                        .cornerRadius(8)
                }

                HStack {
                    Text("Bank/Broker")
                    Spacer()
                    Text(balance.bankBrokerName)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Transaction Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Investment Details Section
            Section {
                HStack {
                    Text("Ticker")
                    Spacer()
                    Text(balance.ticker.isEmpty ? "—" : balance.ticker)
                        .foregroundColor(.secondary)
                }

                if let name = balance.name, !name.isEmpty {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(name)
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text("Number of Stocks")
                    Spacer()
                    Text("\(balance.numberOfStocks)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Stock Price")
                    Spacer()
                    Text(balance.stockPrice.formatted(fractionDigits: 2))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Investment Details")
                    .foregroundStyle(tab.color())
            }

            // MARK: - Financial Summary Section
            Section {
                HStack {
                    Text("Transaction Cost")
                    Spacer()
                    Text(balance.transactionCost.formatted(fractionDigits: 2))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Amount")
                    Spacer()
                    Text(balance.amount.formatted(fractionDigits: 2))
                        .fontWeight(.semibold)
                        .foregroundColor(balance.amount < 0 ? .red : .green)
                }
            } header: {
                Text("Financial Summary")
                    .foregroundStyle(tab.color())
            } footer: {
                Text("Amount is negative for buy/withdrawal transactions (money out) and positive for sell/deposit transactions (money in)")
                    .font(.caption)
            }

            // MARK: - Related Investment Section
            if let investment = balance.investment {
                Section {
                    NavigationLink {
                        InvestmentDetailView(investment: investment, tab: .investment)
                    } label: {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.purple)
                            Text("View Related Investment")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Related Records")
                        .foregroundStyle(tab.color())
                }
            }

            // MARK: - Information Section
            Section {
                HStack {
                    Text("Created")
                    Spacer()
                    Text(balance.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Modified")
                    Spacer()
                    Text(balance.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Information")
                    .foregroundStyle(tab.color())
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .tint(tab.color())
    }
}

#Preview {
    NavigationStack {
        BalanceDetailView(
            balance: Balance(
                transactionDate: Date(),
                transactionType: .buy,
                bankBrokerName: "Test Broker",
                ticker: "AAPL",
                name: "Apple Inc.",
                numberOfStocks: 100,
                stockPrice: 150.50,
                transactionCost: 25.00
            ),
            tab: .balance
        )
    }
}
