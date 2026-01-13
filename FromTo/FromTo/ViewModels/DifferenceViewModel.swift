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

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var absoluteDifference: Decimal {
        return toValue - fromValue
    }

    var relativeDifference: Decimal? {
        guard fromValue != 0 else { return nil }
        return (toValue - fromValue) / fromValue
    }

    var relativeDifferenceFormatted: String {
        guard let relDiff = relativeDifference else {
            return "N/A (division by zero)"
        }
        // Convert to percentage (multiply by 100) and format
        let percentage = relDiff * 100
        return percentage.formatted(fractionDigits: 2) + "%"
    }

    // MARK: - Initialization
    init() {
        loadFromDefaults()
        setupPersistence()
    }

    // MARK: - Persistence
    private func setupPersistence() {
        // Save to UserDefaults whenever any property changes
        Publishers.CombineLatest(
            $fromValue,
            $toValue
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            self?.saveToDefaults()
        }
        .store(in: &cancellables)
    }

    private func saveToDefaults() {
        UserDefaults.standard.set("\(fromValue)", forKey: "com.fromto.difference.fromValue")
        UserDefaults.standard.set("\(toValue)", forKey: "com.fromto.difference.toValue")
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
    }
}
