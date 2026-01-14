//
//  CloudKeyValueStore.swift
//  FromTo
//
//  Created by Claude Code on 14-01-2026.
//

import Foundation
import Combine

/// Singleton service for managing iCloud Key-Value Storage
/// Provides automatic fallback to UserDefaults during migration and when iCloud is unavailable
@MainActor
class CloudKeyValueStore: ObservableObject {
    static let shared = CloudKeyValueStore()

    private let store = NSUbiquitousKeyValueStore.default
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    /// Published property to notify observers of external changes
    @Published private(set) var lastSyncDate: Date?

    private init() {
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Listen for changes from iCloud
        NotificationCenter.default.publisher(
            for: NSUbiquitousKeyValueStore.didChangeExternallyNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        .store(in: &cancellables)

        // Sync on init
        store.synchronize()
    }

    private func handleExternalChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }

        // Handle different change reasons
        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            lastSyncDate = Date()
            // Post notification for observers to refresh their data
            NotificationCenter.default.post(
                name: .cloudKeyValueStoreDidUpdate,
                object: self,
                userInfo: userInfo
            )

        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("iCloud KVS quota exceeded")

        case NSUbiquitousKeyValueStoreAccountChange:
            print("iCloud account changed")

        default:
            break
        }
    }

    // MARK: - Migration

    /// Migrates a value from UserDefaults to iCloud KVS if not already migrated
    /// Returns true if migration occurred, false if already migrated or no value to migrate
    func migrateFromUserDefaults(key: String) -> Bool {
        // Check if already migrated
        guard store.object(forKey: key) == nil else {
            return false
        }

        // Migrate from UserDefaults if exists
        if let value = userDefaults.object(forKey: key) {
            store.set(value, forKey: key)
            store.synchronize()
            return true
        }

        return false
    }

    // MARK: - String Operations

    func setString(_ value: String, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func getString(forKey key: String, fallbackToUserDefaults: Bool = true) -> String? {
        if let value = store.string(forKey: key) {
            return value
        }

        if fallbackToUserDefaults {
            return userDefaults.string(forKey: key)
        }

        return nil
    }

    // MARK: - Bool Operations

    func setBool(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
        store.synchronize()
    }

    func getBool(forKey key: String, fallbackToUserDefaults: Bool = true) -> Bool? {
        // Check if key exists in iCloud KVS
        if store.object(forKey: key) != nil {
            return store.bool(forKey: key)
        }

        if fallbackToUserDefaults {
            if userDefaults.object(forKey: key) != nil {
                return userDefaults.bool(forKey: key)
            }
        }

        return nil
    }

    // MARK: - Decimal Operations

    func setDecimal(_ value: Decimal, forKey key: String) {
        store.set("\(value)", forKey: key)
        store.synchronize()
    }

    func getDecimal(forKey key: String, fallbackToUserDefaults: Bool = true) -> Decimal? {
        if let string = store.string(forKey: key),
           let value = Decimal(string: string) {
            return value
        }

        if fallbackToUserDefaults,
           let string = userDefaults.string(forKey: key),
           let value = Decimal(string: string) {
            return value
        }

        return nil
    }

    // MARK: - Remove

    func remove(forKey key: String) {
        store.removeObject(forKey: key)
        store.synchronize()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKeyValueStoreDidUpdate = Notification.Name("cloudKeyValueStoreDidUpdate")
}
