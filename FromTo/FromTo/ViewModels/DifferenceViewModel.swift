//
//  DifferenceViewModel.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation
import Combine

class DifferenceViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var fromValue: Decimal = 0
    @Published var toValue: Decimal = 0
    @Published var isRelativeMode: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties for Absolute Mode
    var absoluteDifferenceAbsolute: Decimal {
        return toValue - fromValue
    }

    var relativeDifferenceAbsolute: Decimal? {
        guard fromValue != 0 else { return nil }
        return (toValue - fromValue) / fromValue
    }

    var relativeDifferenceAbsoluteFormatted: String {
        guard let relDiff = relativeDifferenceAbsolute else {
            return "N/A (division by zero)"
        }
        // Convert to percentage (multiply by 100) and format
        let percentage = relDiff * 100
        return percentage.formatted() + " %"
    }

    // MARK: - Computed Properties for Relative Mode
    var absoluteDifferenceRelative: Decimal {
        return fromValue * toValue
    }

    var cumulativeDifference: Decimal {
        return fromValue * (1 + toValue)
    }

    // MARK: - Initialization
    init() {
        loadFromDefaults()
        setupPersistence()
    }

    // MARK: - Persistence
    private func setupPersistence() {
        // Save to UserDefaults whenever any property changes
        Publishers.CombineLatest3(
            $fromValue,
            $toValue,
            $isRelativeMode
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.saveToDefaults()
        }
        .store(in: &cancellables)
    }

    private func saveToDefaults() {
        UserDefaults.standard.set("\(fromValue)", forKey: "com.fromto.difference.fromValue")
        UserDefaults.standard.set("\(toValue)", forKey: "com.fromto.difference.toValue")
        UserDefaults.standard.set(isRelativeMode, forKey: "com.fromto.difference.isRelativeMode")
    }

    private func loadFromDefaults() {
        if let savedFrom = UserDefaults.standard.string(forKey: "com.fromto.difference.fromValue"),
           let value = Decimal(string: savedFrom) {
            fromValue = value
        }

        if let savedTo = UserDefaults.standard.string(forKey: "com.fromto.difference.toValue"),
           let value = Decimal(string: savedTo) {
            toValue = value
        }

        isRelativeMode = UserDefaults.standard.bool(forKey: "com.fromto.difference.isRelativeMode")
    }
}
