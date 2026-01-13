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

    // MARK: - let values for keyboard buttons
    let circleFrameSize: CGFloat = 40
    let opacityValue: Double = 0.2
    let hPadding: CGFloat = 10
    let vPadding: CGFloat = 8

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Values Section
                Section {
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
                } header: {
                    HStack {
                        Text("Values")
                        Spacer()
                        Button(action: {
                            swapValues()
                        }) {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                        }
                        .buttonStyle(.borderedProminent)
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
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                            .background(Capsule().fill(.red).opacity(opacityValue))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.teal)
                            .frame(width: circleFrameSize, height: circleFrameSize, alignment: .center)
                            .background(Circle().fill(.teal).opacity(opacityValue))
                    }
                    .disabled(focusedField == .fromValue || focusedField == nil)
                    
                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                            .frame(width: circleFrameSize, height: circleFrameSize, alignment: .center)
                            .background(Circle().fill(.blue).opacity(opacityValue))
                    }
                    .disabled(focusedField == .toValue || focusedField == nil)
                    
                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .foregroundColor(.green)
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                            .background(Capsule().fill(.green).opacity(opacityValue))
                    }
                }
            }
        }
    }
    // MARK: - Helper Methods
    private func swapValues() {
        let temp = viewModel.fromValue
        viewModel.fromValue = viewModel.toValue
        viewModel.toValue = temp
    }

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


}

#Preview {
    DifferenceView()
}
