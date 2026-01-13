//
//  CurrencySelectionView.swift
//  FromTo
//
//  Created by Claude Code on 13-01-2026.
//

import SwiftUI

struct CurrencySelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCurrency: String
    let availableCurrencies: [String]
    let title: String

    @State private var searchText = ""

    var filteredCurrencies: [String] {
        if searchText.isEmpty {
            return availableCurrencies
        } else {
            return availableCurrencies.filter { currency in
                let currencyName = Locale.current.localizedString(forCurrencyCode: currency) ?? currency
                return currency.localizedCaseInsensitiveContains(searchText) ||
                       currencyName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func currencyName(for code: String) -> String {
        return Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar always visible at top
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search currencies", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.vertical, 8)

            List {
                ForEach(filteredCurrencies, id: \.self) { currency in
                    Button(action: {
                        selectedCurrency = currency
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currency)
                                    .foregroundColor(.primary)
                                    .font(.body)
                                HStack{
                                    Spacer()
                                    Text(currencyName(for: currency))
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                }
                            }
                            Spacer()
                            if currency == selectedCurrency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CurrencySelectionView(
            selectedCurrency: .constant("USD"),
            availableCurrencies: Locale.commonISOCurrencyCodes.sorted(),
            title: "Select Currency"
        )
    }
}
