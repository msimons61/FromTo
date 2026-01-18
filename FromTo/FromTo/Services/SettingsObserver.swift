//
//  SettingsObserver.swift
//  FromTo
//
//  Created by Claude Code on 18-01-2026.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class SettingsObserver: ObservableObject {
    @Published var colorScheme: ColorScheme?
    @Published var displayMode: DisplayMode

    private let modelContainer: ModelContainer
    private var lastModified: Date?
    private var timer: Timer?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        // Initialize with default
        self.displayMode = .system

        // Load initial settings
        loadSettings()

        // Start observing for changes
        startObserving()
    }

    private func startObserving() {
        // Poll every 0.5 seconds for changes
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }

    private func checkForUpdates() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Settings>()

        guard let settings = try? context.fetch(descriptor).first else { return }

        // Check if modified since last check
        if lastModified != settings.modifiedAt {
            loadSettings()
        }
    }

    private func loadSettings() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Settings>()

        guard let settings = try? context.fetch(descriptor).first else { return }

        // Update published properties (this triggers App body re-evaluation)
        lastModified = settings.modifiedAt
        displayMode = settings.displayMode
        colorScheme = settings.colorScheme
    }

    deinit {
        timer?.invalidate()
    }
}
