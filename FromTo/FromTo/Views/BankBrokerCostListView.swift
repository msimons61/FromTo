//
//  BankBrokerCostListView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI
import SwiftData

struct BankBrokerCostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BankBrokerCost.startDate, order: .reverse) private var providers: [BankBrokerCost]

    let tab: AppTab

    var activeProviders: [BankBrokerCost] {
        providers.filter { $0.isActive(on: Date()) }
    }

    var expiredProviders: [BankBrokerCost] {
        providers.filter { !$0.isActive(on: Date()) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !activeProviders.isEmpty {
                    Section {
                        ForEach(activeProviders) { provider in
                            NavigationLink {
                                BankBrokerCostDetailView(
                                    provider: provider,
                                    tab: tab
                                )
                            } label: {
                                BankBrokerCostRowView(provider: provider, isActive: true)
                            }
                        }
                        .onDelete { offsets in
                            deleteProviders(from: activeProviders, at: offsets)
                        }
                    } header: {
                        Text("Active").foregroundStyle(tab.color())
                    }
                }

                if !expiredProviders.isEmpty {
                    Section {
                        ForEach(expiredProviders) { provider in
                            NavigationLink {
                                BankBrokerCostDetailView(
                                    provider: provider,
                                    tab: tab
                                )
                            } label: {
                                BankBrokerCostRowView(provider: provider, isActive: false)
                            }
                        }
                        .onDelete { offsets in
                            deleteProviders(from: expiredProviders, at: offsets)
                        }
                    } header: {
                        Text("Expired").foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Provider Costs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        createNewProvider()
                    } label: {
                        Label("Add Provider", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .overlay {
                if providers.isEmpty {
                    ContentUnavailableView {
                        Label("No Provider Costs", systemImage: "banknote")
                    } description: {
                        Text("Tap the + button to add your first bank or broker cost structure")
                    }
                }
            }
            .tint(tab.color())
        }
    }

    private func createNewProvider() {
        let newProvider = BankBrokerCost()
        modelContext.insert(newProvider)
        try? modelContext.save()
    }

    private func deleteProviders(from list: [BankBrokerCost], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    BankBrokerCostListView(tab: .settings)
}
