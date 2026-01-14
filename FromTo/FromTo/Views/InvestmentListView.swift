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
    @EnvironmentObject var settings: SettingsData
    @Query(sort: \Investment.modifiedAt, order: .reverse) private var investments: [Investment]

    let tab: AppTab

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
                        InvestmentRowView(investment: investment, settings: settings)
                    }
                }
                .onDelete(perform: deleteInvestments)
            }
            .navigationTitle("Investments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewInvestment()
                    } label: {
                        Label("Add Investment", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .overlay {
                if investments.isEmpty {
                    ContentUnavailableView {
                        Label("No Investments", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Tap the + button to create your first investment calculation")
                    }
                }
            }
            .tint(tab.color())
        }
    }

    private func createNewInvestment() {
        let newInvestment = Investment(
            currencyRate: settings.currencyRate,
            fixedCost: settings.defaultFixedCost,
            variableCost: settings.defaultVariableCost,
            maximumCost: settings.defaultMaximumCost
        )
        modelContext.insert(newInvestment)

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
    let settings: SettingsData

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(investment.name ?? "Untitled")
                    .font(.headline)
                Spacer()
                Text("\(investment.numberOfStocks) stocks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("\(investment.availableAmount.formatted(fractionDigits: 2)) \(settings.fromCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(investment.investedAmount.formatted(fractionDigits: 2)) \(settings.toCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(investment.transactionDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InvestmentListView(tab: .investment)
        .environmentObject(SettingsData())
}
