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
    @State private var differenceMode: DifferenceMode = .absolute
    let tab: AppTab
    var hPadding: CGFloat = 10
    var vPadding: CGFloat = 8

    enum Field {
        case fromValue, toValue
    }

    enum DifferenceMode: String, CaseIterable, Identifiable {
        case absolute = "Absolute"
        case relative = "Relative"

        var id: String { self.rawValue }
    }

    // MARK: - let values for keyboard buttons
    let circleFrameSize: CGFloat = 40
    let opacityValue: Double = 0.2

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
                            fractionDigits: 38,
                            tab: tab
                        )
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .fromValue)
                    }

                    HStack {
                        Text("To")
                        Spacer()
                        if differenceMode == .absolute {
                            DecimalTextFieldNonOptional(
                                label: "To",
                                value: $viewModel.toValue,
                                fractionDigits: 38,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .toValue)
                        } else {
                            PercentageTextField(
                                label: "To",
                                tab:tab,
                                value: $viewModel.toValue
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .toValue)
                        }
                    }

                    Picker("Mode", selection: $differenceMode) {
                        
                        ForEach(DifferenceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(tab.color())
                    .onChange(of: differenceMode) { _, newMode in
                        viewModel.isRelativeMode = (newMode == .relative)
                    }
                } header: {
                    HStack {
                        Text("Values")
                            .foregroundStyle(tab.color())
                        Spacer()
                        if differenceMode == .absolute {
                            Button(action: {
                                swapValues()
                            }) {
                                Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                    .circleBackground(fgColor: tab.color(), font: .body.bold(), size: 5)
                            }
                        }
                    }
                }

                // MARK: - Results Section
                Section {
                    if differenceMode == .absolute {
                        HStack {
                            Text("Absolute Difference")
                            Spacer()
                            Text(viewModel.absoluteDifferenceAbsolute.formatted())
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Relative Difference")
                            Spacer()
                            Text(viewModel.relativeDifferenceAbsoluteFormatted)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Absolute Difference")
                            Spacer()
                            Text(viewModel.absoluteDifferenceRelative.formatted())
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Cumulative Difference")
                            Spacer()
                            Text(viewModel.cumulativeDifference.formatted())
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Results")
                        .foregroundStyle(tab.color())
                }
            }
            .navigationTitle("Difference")
            .onAppear {
                // Sync differenceMode from viewModel on appear
                differenceMode = viewModel.isRelativeMode ? .relative : .absolute
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        clearCurrentField()
                    }) {
                        Text("Clear")
                            .kbCapsuleBackground(color: .red)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        moveToPreviousField()
                    }) {
                        Image(systemName: "chevron.up")
                            .kbCapsuleBackground(color: .teal)
                    }
                    .disabled(focusedField == .fromValue || focusedField == nil)
                    
                    Button(action: {
                        moveToNextField()
                    }) {
                        Image(systemName: "chevron.down")
                            .kbCapsuleBackground(color: .blue)
                    }
                    .disabled(focusedField == .toValue || focusedField == nil)
                    
                    Button(action: {
                        focusedField = nil
                    }) {
                        Text("Done")
                            .kbCapsuleBackground(color: .green)
                    }
                }
            }
            .tint(tab.color())
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
    DifferenceView(tab: .difference)
}
