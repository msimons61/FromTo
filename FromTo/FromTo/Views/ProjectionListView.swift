//
//  ProjectionListView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct ProjectionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Projection.modifiedAt, order: .reverse) private var projections: [Projection]
    @Query private var settingsQuery: [Settings]

    let tab: AppTab

    private var settings: Settings? {
        settingsQuery.first
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(projections) { projection in
                    NavigationLink {
                        ProjectionDetailView(
                            projection: projection,
                            tab: tab
                        )
                    } label: {
                        ProjectionRowView(projection: projection)
                    }
                }
                .onDelete(perform: deleteProjections)
            }
            .navigationTitle("Projections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewProjection()
                    } label: {
                        Label("Add Projection", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .overlay {
                if projections.isEmpty {
                    ContentUnavailableView {
                        Label("No Projections", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Tap the + button to create your first projection calculation")
                    }
                }
            }
            .tint(tab.color())
        }
    }

    private func createNewProjection() {
        // Get or create settings
        let settings = settings ?? Settings()
        if settingsQuery.isEmpty {
            modelContext.insert(settings)
        }

        let newProjection = Projection(
            ticker: "",
            currencyRate: settings.effectiveCurrencyRate,
            fixedCost: settings.applyCost ? settings.defaultFixedCost : 0,
            variableCost: settings.applyCost ? settings.defaultVariableCost : 0,
            maximumCost: settings.applyCost ? settings.defaultMaximumCost : nil,
            baseCurrency: settings.baseCurrency,
            transactionCurrency: settings.transactionCurrency,
            bankBrokerName: settings.bankBrokerName
        )
        modelContext.insert(newProjection)

        // Save immediately so it appears in list
        try? modelContext.save()
    }

    private func deleteProjections(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(projections[index])
        }
        try? modelContext.save()
    }
}

struct ProjectionRowView: View {
    let projection: Projection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !projection.ticker.isEmpty {
                    Text(projection.ticker)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Text(projection.name ?? "Untitled")
                    .font(projection.ticker.isEmpty ? .headline : .subheadline)
                    .foregroundColor(projection.ticker.isEmpty ? .primary : .secondary)
                Spacer()
                Text("\(projection.actualNumberOfStocks)/\(projection.numberOfStocks) stocks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Available: \(projection.baseAmountAvailable.formatted(fractionDigits: 2)) \(projection.baseCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            HStack {
                Text("Invested: \(projection.investedAmount.formatted(fractionDigits: 2)) \(projection.transactionCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(projection.transactionDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProjectionListView(tab: .projection)
}
