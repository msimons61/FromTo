//
//  DecimalTextField.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct DecimalTextField: View {
    let label: String
    @Binding var value: Decimal?
    let fractionDigits: Int
    let includeGrouping: Bool
    let suffix: String?
    let tab: AppTab

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    private let formatter = DecimalFormatterUtility.shared

    init(
        label: String,
        value: Binding<Decimal?>,
        fractionDigits: Int = 2,
        includeGrouping: Bool = true,
        suffix: String? = nil,
        tab: AppTab = .investment
    ) {
        self.label = label
        self._value = value
        self.fractionDigits = fractionDigits
        self.includeGrouping = includeGrouping
        self.suffix = suffix
        self.tab = tab
    }

    var body: some View {
        HStack {
            TextField(
                label,
                text: $textValue,
                prompt: Text(formatter.placeholderWithGrouping(fractionDigits: fractionDigits))
            )
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Parse the text to update the bound value
                if newValue.isEmpty {
                    value = nil
                } else if let parsed = formatter.parse(newValue) {
                    value = parsed
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    // Format the value when focus is lost
                    if let currentValue = value {
                        textValue = formatter.format(
                            currentValue,
                            fractionDigits: fractionDigits,
                            includeGrouping: includeGrouping,
                            enforceMinimumDigits: suffix != nil
                        )
                    }
                }
            }
            .onAppear {
                // Initialize text value from bound value
                if let currentValue = value {
                    textValue = formatter.format(
                        currentValue,
                        fractionDigits: fractionDigits,
                        includeGrouping: includeGrouping,
                        enforceMinimumDigits: suffix != nil
                    )
                }
            }
            .onChange(of: value) { _, newValue in
                // Update text value when bound value changes externally
                // Always clear if value is nil, even when focused (for clear button)
                if newValue == nil {
                    textValue = ""
                } else if !isFocused {
                    if let currentValue = newValue {
                        textValue = formatter.format(
                            currentValue,
                            fractionDigits: fractionDigits,
                            includeGrouping: includeGrouping,
                            enforceMinimumDigits: suffix != nil
                        )
                    }
                }
            }

            if let suffix = suffix {
                Text(suffix)
                    .foregroundColor(.secondary)
            }

            if !textValue.isEmpty {
                Button(action: {
                    textValue = ""
                    value = nil
                    isFocused = true
                }) {
                    Image(systemName: "xmark")
                        .circleBackground(fgColor: tab.color())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Non-optional variant
struct DecimalTextFieldNonOptional: View {
    let label: String
    @Binding var value: Decimal
    let fractionDigits: Int
    let includeGrouping: Bool
    let suffix: String?
    let tab: AppTab

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    private let formatter = DecimalFormatterUtility.shared

    init(
        label: String,
        value: Binding<Decimal>,
        fractionDigits: Int = 2,
        includeGrouping: Bool = true,
        suffix: String? = nil,
        tab: AppTab
    ) {
        self.label = label
        self._value = value
        self.fractionDigits = fractionDigits
        self.includeGrouping = includeGrouping
        self.suffix = suffix
        self.tab = tab
    }

    var body: some View {
        HStack {
            TextField(
                label,
                text: $textValue,
                prompt: Text(formatter.placeholderWithGrouping(fractionDigits: fractionDigits))
            )
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Parse the text to update the bound value
                if newValue.isEmpty {
                    value = 0
                } else if let parsed = formatter.parse(newValue) {
                    value = parsed
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    // Format the value when focus is lost
                    textValue = formatter.format(
                        value,
                        fractionDigits: fractionDigits,
                        includeGrouping: includeGrouping,
                        enforceMinimumDigits: suffix != nil,
                    )
                }
            }
            .onAppear {
                // Initialize text value from bound value
                textValue = formatter.format(
                    value,
                    fractionDigits: fractionDigits,
                    includeGrouping: includeGrouping,
                    enforceMinimumDigits: suffix != nil
                )
            }
            .onChange(of: value) { _, newValue in
                // Update text value when bound value changes externally
                // Always clear if value is 0, even when focused (for clear button)
                if newValue == 0 {
                    textValue = ""
                } else if !isFocused {
                    textValue = formatter.format(
                        newValue,
                        fractionDigits: fractionDigits,
                        includeGrouping: includeGrouping,
                        enforceMinimumDigits: suffix != nil
                    )
                }
            }

            if let suffix = suffix {
                Text(suffix)
                    .foregroundColor(.secondary)
            }

            if !textValue.isEmpty {
                Button(action: {
                    textValue = ""
                    value = 0
                    isFocused = true
                }) {
                    Image(systemName: "xmark")
                        .circleBackground(fgColor: tab.color())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
