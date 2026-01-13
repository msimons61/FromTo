//
//  FromToApp.swift
//  FromTo
//
//  Created by Marlon Simons on 12-01-2026.
//

import SwiftUI

@main
struct FromToApp: App {
    @StateObject private var settings = SettingsData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .preferredColorScheme(settings.colorScheme)
        }
    }
}
