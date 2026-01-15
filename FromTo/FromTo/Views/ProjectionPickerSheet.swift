//
//  ProjectionPickerSheet.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct ProjectionPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Projection.transactionDate, order: .reverse) private var projections: [Projection]

    let tab: AppTab
    let onCreate: (Investment) -> Void

    var body: some View {
        NavigationStack {
            List {
                if projections.isEmpty {
                    ContentUnavailableView {
                        Label("No Projections", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Create a projection first to convert it to an investment")
                    }
                } else {
                    ForEach(projections) { projection in
                        Button(action: {
                            createInvestmentFromProjection(projection)
                        }) {
                            ProjectionPickerRow(projection: projection)
                        }
                    }
                }
            }
            .navigationTitle("Select Projection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .tint(tab.color())
        }
    }

    private func createInvestmentFromProjection(_ projection: Projection) {
        let newInvestment = Investment.from(projection)
        modelContext.insert(newInvestment)
        try? modelContext.save()

        onCreate(newInvestment)
        dismiss()
    }
}

struct ProjectionPickerRow: View {
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
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
            }

            HStack {
                Text("\(projection.actualNumberOfStocks) stocks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(projection.investedAmount.formatted(fractionDigits: 2)) \(projection.transactionCurrency)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Text(projection.transactionDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
