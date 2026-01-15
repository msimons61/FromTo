//
//  InvestmentListView.swift
//  FromTo
//
//  Created by Claude Code on 14-01-2026.
//

import SwiftUI
import SwiftData

struct InvestmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Investment.modifiedAt, order: .reverse) private var investments: [Investment]
    @Query private var settingsQuery: [Settings]

    let tab: AppTab

    @State private var showingProjectionPicker = false
    @State private var selectedInvestment: Investment?

    private var settings: Settings? {
        settingsQuery.first
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(investments) { investment in
                    NavigationLink {
                        InvestmentDetailView(
                            investment: investment,
                            tab: tab
                        )
                    } label: {
                        InvestmentRowView(investment: investment)
                    }
                }
                .onDelete(perform: deleteInvestments)
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            createNewInvestment()
                        } label: {
                            Label("New Investment", systemImage: "plus")
                        }

                        Button {
                            showingProjectionPicker = true
                        } label: {
                            Label("From Projection", systemImage: "arrow.right.circle")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .overlay {
                if investments.isEmpty {
                    ContentUnavailableView {
                        Label("No Investments", systemImage: "chart.bar.doc.horizontal")
                    } description: {
                        Text("Tap the + button to record your first investment")
                    }
                }
            }
            .sheet(isPresented: $showingProjectionPicker) {
                ProjectionPickerSheet(tab: tab) { newInvestment in
                    selectedInvestment = newInvestment
                }
            }
            .tint(tab.color())
        }
    }

    private func createNewInvestment() {
        // Get or create settings
        let settings = settings ?? Settings()
        if settingsQuery.isEmpty {
            modelContext.insert(settings)
        }

        let newInvestment = Investment(
            currencyRate: settings.effectiveCurrencyRate,
            fixedCost: settings.applyCost ? settings.defaultFixedCost : 0,
            variableCost: settings.applyCost ? settings.defaultVariableCost : 0,
            maximumCost: settings.applyCost ? (settings.defaultMaximumCost ?? 0) : 0,
            baseCurrency: settings.baseCurrency,
            transactionCurrency: settings.transactionCurrency,
            bankBrokerName: settings.bankBrokerName
        )
        modelContext.insert(newInvestment)

        // Create associated Balance record
        let newBalance = Balance.from(newInvestment)
        modelContext.insert(newBalance)
        newInvestment.balance = newBalance

        // Save immediately so it appears in list
        try? modelContext.save()
    }

    private func deleteInvestments(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(investments[index])
        }
        try? modelContext.save()
    }
}

struct InvestmentRowView: View {
    let investment: Investment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !investment.ticker.isEmpty {
                    Text(investment.ticker)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text(investment.name ?? "Untitled")
                    .font(investment.ticker.isEmpty ? .headline : .subheadline)
                    .foregroundColor(investment.ticker.isEmpty ? .primary : .secondary)
                Spacer()
                Text("\(investment.numberOfStocks) stocks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Invested: \(investment.totalInvested.formatted(fractionDigits: 2)) \(investment.transactionCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text("Total: \(investment.totalAmount.formatted(fractionDigits: 2)) \(investment.transactionCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(investment.transactionDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InvestmentListView(tab: .investment)
}
