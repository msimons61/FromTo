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
                            fractionDigits: 6,
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
                                fractionDigits: 6,
                                tab: tab
                            )
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .toValue)
                        } else {
                            PercentageTextField(
                                label: "To",
                                tab: tab,
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
                    .onChange(of: differenceMode) { oldMode, newMode in
                        viewModel.isRelativeMode = (newMode == .relative)
                        // Convert toValue when switching modes
                        if oldMode == .absolute && newMode == .relative {
                            // Switching to Relative: toValue = Relative Difference
                            viewModel.toValue = viewModel.relativeDifferenceAbsolute ?? 0
                        } else if oldMode == .relative && newMode == .absolute {
                            // Switching to Absolute: toValue = Cumulative Difference
                            viewModel.toValue = viewModel.cumulativeDifference
                        }
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
                                    .circleBackground(fgColor: tab.color(), font: .body.bold(), padding: 5)
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
            .tint(tab.color())
            .toolbar { toolbarContent }
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
            focusedField = nil  // First field, no previous
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
            focusedField = nil  // Last field, dismiss keyboard
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            KeyboardToolbarButton.button(.clear) { clearCurrentField() }

            Spacer()

            KeyboardToolbarButton.button(.previous) { moveToPreviousField() }

            KeyboardToolbarButton.button(.next) { moveToNextField() }

            KeyboardToolbarButton.button(.done(tab.color())) { focusedField = nil }
        }
    }

}

#Preview {
    DifferenceView(tab: .difference)
}
