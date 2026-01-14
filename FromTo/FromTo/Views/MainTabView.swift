//
//  MainTabView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

enum AppTab: String, Codable, CaseIterable {
    case investment = "Investment"
    case difference = "Difference"
    case settings = "Settings"

    func color() -> Color {
        switch self {
        case .investment:
            return .blue
        case .difference:
            return .green
        case .settings:
            return .orange
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var settings: SettingsData
    @AppStorage("com.fromto.selectedTab") private var selectedTab: AppTab = .investment

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.investment) {
                InvestmentView(settings: settings, tab: .investment)
            } label: {
                Label("Investment", systemImage: "chart.line.uptrend.xyaxis")
            }

            Tab(value: AppTab.difference) {
                DifferenceView(tab: .difference)
            } label: {
                Label("Difference", systemImage: "arrow.left.arrow.right")
            }

            Tab(value: AppTab.settings) {
                SettingsView(tab: .settings)
            } label: {
                Label("Settings", systemImage: "gear")
            }
        }
        .tint(selectedTab.color())
    }
}

#Preview {
    MainTabView()
        .environmentObject(SettingsData())
}
