//
//  PercentageTextField.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

struct PercentageTextField: View {
    let label: String
    let tab: AppTab
    
    @Binding var value: Decimal

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    private let formatter = DecimalFormatterUtility.shared

    init(label: String, tab: AppTab, value: Binding<Decimal>) {
        self.label = label
        self.tab = tab
        self._value = value
    }

    var body: some View {
        HStack {
            TextField(
                label,
                text: $textValue,
                prompt: Text(placeholderText)
            )
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Parse the text (displayed as percentage) and convert to decimal
                // e.g., "0.1%" -> parse "0.1" -> store as 0.001
                if newValue.isEmpty {
                    value = 0
                } else {
                    // Remove % symbol if present
                    let cleanValue = newValue.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
                    if let parsed = formatter.parse(cleanValue) {
                        // Convert percentage to decimal (divide by 100)
                        value = parsed / 100
                    }
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    // Format the value when focus is lost
                    // Convert decimal to percentage for display (multiply by 100)
                    let percentageValue = value * 100
                    textValue = formatter.format(percentageValue, fractionDigits: 38, includeGrouping: false, enforceMinimumDigits: false)
                }
            }
            .onAppear {
                // Initialize text value from bound value
                // Convert decimal to percentage for display (multiply by 100)
                let percentageValue = value * 100
                textValue = formatter.format(percentageValue, fractionDigits: 6, includeGrouping: false, enforceMinimumDigits: false)
            }
            .onChange(of: value) { _, newValue in
                // Update text value when bound value changes externally
                // Always clear if value is 0, even when focused (for clear button)
                if newValue == 0 {
                    textValue = ""
                } else if !isFocused {
                    let percentageValue = newValue * 100
                    textValue = formatter.format(percentageValue, fractionDigits: 38, includeGrouping: false, enforceMinimumDigits: false)
                }
            }

            Text("%")
                .foregroundColor(.secondary)

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

    private var placeholderText: String {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        return "0\(decimalSeparator)1"
    }
}

// MARK: - Optional Percentage TextField
struct PercentageTextFieldOptional: View {
    let label: String
    let tab: AppTab
    
    @Binding var value: Decimal?

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    private let formatter = DecimalFormatterUtility.shared

    init(label: String, tab: AppTab, value: Binding<Decimal?>) {
        self.label = label
        self.tab = tab
        self._value = value
    }

    var body: some View {
        HStack {
            TextField(
                label,
                text: $textValue,
                prompt: Text(placeholderText)
            )
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .onChange(of: textValue) { _, newValue in
                // Parse the text (displayed as percentage) and convert to decimal
                if newValue.isEmpty {
                    value = nil
                } else {
                    // Remove % symbol if present
                    let cleanValue = newValue.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
                    if let parsed = formatter.parse(cleanValue) {
                        // Convert percentage to decimal (divide by 100)
                        value = parsed / 100
                    }
                }
            }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    // Format the value when focus is lost
                    if let currentValue = value {
                        let percentageValue = currentValue * 100
                        textValue = formatter.format(percentageValue, fractionDigits: 38, includeGrouping: false, enforceMinimumDigits: false)
                    }
                }
            }
            .onAppear {
                // Initialize text value from bound value
                if let currentValue = value {
                    let percentageValue = currentValue * 100
                    textValue = formatter.format(percentageValue, fractionDigits: 38, includeGrouping: false, enforceMinimumDigits: false)
                }
            }
            .onChange(of: value) { _, newValue in
                // Update text value when bound value changes externally
                // Always clear if value is nil, even when focused (for clear button)
                if newValue == nil {
                    textValue = ""
                } else if !isFocused {
                    if let currentValue = newValue {
                        let percentageValue = currentValue * 100
                        textValue = formatter.format(percentageValue, fractionDigits: 38, includeGrouping: false, enforceMinimumDigits: false)
                    }
                }
            }

            Text("%")
                .foregroundColor(.secondary)

            if !textValue.isEmpty {
                Button(action: {
                    textValue = ""
                    value = nil
                    isFocused = true
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(tab.color())
                        .font(.caption)
                        .padding(5)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var placeholderText: String {
        let decimalSeparator = Locale.current.decimalSeparator ?? "."
        return "0\(decimalSeparator)1"
    }
}
