//
//  DifferenceViewModel.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import Foundation
import Combine

@MainActor
class DifferenceViewModel: ObservableObject {
    // MARK: - Cloud Storage
    private let cloudStore = CloudKeyValueStore.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Keys
    private enum Keys {
        static let fromValue = "com.fromto.difference.fromValue"
        static let toValue = "com.fromto.difference.toValue"
        static let isRelativeMode = "com.fromto.difference.isRelativeMode"
    }

    // MARK: - Published Properties
    @Published var fromValue: Decimal {
        didSet {
            cloudStore.setDecimal(fromValue, forKey: Keys.fromValue)
        }
    }

    @Published var toValue: Decimal {
        didSet {
            cloudStore.setDecimal(toValue, forKey: Keys.toValue)
        }
    }

    @Published var isRelativeMode: Bool {
        didSet {
            cloudStore.setBool(isRelativeMode, forKey: Keys.isRelativeMode)
        }
    }

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
        // Load from cloud storage (with UserDefaults fallback)
        self.fromValue = cloudStore.getDecimal(forKey: Keys.fromValue) ?? 0
        self.toValue = cloudStore.getDecimal(forKey: Keys.toValue) ?? 0
        self.isRelativeMode = cloudStore.getBool(forKey: Keys.isRelativeMode) ?? false

        setupCloudObserver()
    }

    // MARK: - Cloud Sync
    private func setupCloudObserver() {
        NotificationCenter.default.publisher(
            for: .cloudKeyValueStoreDidUpdate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.reloadFromCloud()
        }
        .store(in: &cancellables)
    }

    private func reloadFromCloud() {
        // Reload all properties from cloud storage (without UserDefaults fallback)
        // This prevents overwriting cloud data with stale local data

        if let value = cloudStore.getDecimal(forKey: Keys.fromValue, fallbackToUserDefaults: false) {
            fromValue = value
        }

        if let value = cloudStore.getDecimal(forKey: Keys.toValue, fallbackToUserDefaults: false) {
            toValue = value
        }

        if let value = cloudStore.getBool(forKey: Keys.isRelativeMode, fallbackToUserDefaults: false) {
            isRelativeMode = value
        }
    }

    func performCloudMigration() async {
        // Migrate all keys from UserDefaults to iCloud KVS
        let keys = [Keys.fromValue, Keys.toValue, Keys.isRelativeMode]

        var migratedCount = 0
        for key in keys {
            if cloudStore.migrateFromUserDefaults(key: key) {
                migratedCount += 1
            }
        }

        if migratedCount > 0 {
            print("Migrated \(migratedCount) difference calculator keys to iCloud KVS")
        } else {
            print("No difference calculator migration needed")
        }
    }
}
