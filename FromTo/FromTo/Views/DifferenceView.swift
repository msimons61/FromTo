//
//  DifferenceView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct DifferenceView: View {
    @StateObject private var viewModel = DifferenceViewModel()
    @FocusState private var focusedField: Field?

    enum Field {
        case fromValue, toValue
    }

    // MARK: - Helper Methods
    private func clearCurrentField() {
        guard let field = focusedField else { return }

        switch field {
        case .fromValue:
            viewModel.fromValue = 0
        case .toValue:
            viewModel.toValue = 0
        }
    }

    private func moveToPreviousField() {
        guard let current = focusedField else { return }

        switch current {
        case .fromValue:
            focusedField = nil // First field, no previous
        case .toValue:
            focusedField = .fromValue
        }
    }

    private func moveToNextField() {
        guard let current = focusedField else { return }

        switch current {
        case .fromValue:
            focusedField = .toValue
        case .toValue:
            focusedField = nil // Last field, dismiss keyboard
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Values Section
                Section("Values") {
                    HStack {
                        Text("From")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "From",
                            value: $viewModel.fromValue,
                            fractionDigits: 6
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .fromValue)
                    }

                    HStack {
                        Text("To")
                        Spacer()
                        DecimalTextFieldNonOptional(
                            label: "To",
                            value: $viewModel.toValue,
                            fractionDigits: 6
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .toValue)
                    }
                }

                // MARK: - Results Section
                Section("Results") {
                    HStack {
                        Text("Absolute Difference")
                        Spacer()
                        Text(viewModel.absoluteDifference.formatted(fractionDigits: 6))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Relative Difference")
                        Spacer()
                        Text(viewModel.relativeDifferenceFormatted)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Difference")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        clearCurrentField()
                    }) {
                        Text("Clear")
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.teal)
                    }
                    .disabled(focusedField == .fromValue || focusedField == nil)

                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    .disabled(focusedField == .toValue || focusedField == nil)

                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

#Preview {
    DifferenceView()
}
