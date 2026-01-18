//
//  ProviderCostListView.swift
//  FromTo
//
//  Created by Claude Code on 2026-01-17.
//

import SwiftUI
import SwiftData

enum ProviderSelectionMode {
    case single  // For selecting a provider in Settings
    case manage  // For full CRUD operations
}

struct ProviderCostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BankBrokerProvider.startDate, order: .reverse) private var allProviders: [BankBrokerProvider]

    let selectionMode: ProviderSelectionMode
    @Binding var selectedProviderId: UUID?
    let tab: AppTab

    @State private var showingAddProvider = false

    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if selectionMode == .manage {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingAddProvider = true
                }
            }
        }
    }

    var body: some View {
        List {
            ForEach(allProviders.filter { $0.isActive(on: Date()) }) { provider in
                if selectionMode == .single {
                    Button {
                        selectedProviderId = provider.id
                        dismiss()
                    } label: {
                        HStack {
                            ProviderCostRowView(provider: provider)
                            Spacer()
                            if selectedProviderId == provider.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                } else {
                    NavigationLink {
                        ProviderCostDetailView(provider: provider, tab: tab)
                    } label: {
                        ProviderCostRowView(provider: provider)
                    }
                }
            }
        }
        .navigationTitle(selectionMode == .single ? "Select Provider" : "Cost Providers")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingAddProvider) {
            NavigationStack {
                ProviderCostDetailView(provider: nil, tab: tab)
            }
        }
    }
}
