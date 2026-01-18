//
//  ProviderSelectionView.swift
//  FromTo
//
//  Created by Claude Code on 15-01-2026.
//

import SwiftUI

struct ProviderSelectionView: View {
    @Binding var selectedProvider: String
    let availableProviders: [String]
    let tab: AppTab
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // None option
            Button(action: {
                selectedProvider = ""
                dismiss()
            }) {
                HStack {
                    Text("None")
                    Spacer()
                    if selectedProvider.isEmpty {
                        Image(systemName: "checkmark")
                            .foregroundColor(tab.color())
                    }
                }
            }
            .foregroundColor(.primary)

            // Available providers
            ForEach(availableProviders, id: \.self) { provider in
                Button(action: {
                    selectedProvider = provider
                    dismiss()
                }) {
                    HStack {
                        Text(provider)
                        Spacer()
                        if selectedProvider == provider {
                            Image(systemName: "checkmark")
                                .foregroundColor(tab.color())
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Select Provider")
        .navigationBarTitleDisplayMode(.inline)
        .tint(tab.color())
    }
}

#Preview {
    NavigationStack {
        ProviderSelectionView(
            selectedProvider: .constant("Interactive Brokers"),
            availableProviders: ["Interactive Brokers", "DeGiro", "eToro"],
            tab: .settings
        )
    }
}
