//
//  MainTabView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

enum AppTab: String, Codable, CaseIterable {
    case investment = "Investment"
    case projection = "Projection"
    case difference = "Difference"
    case settings = "Settings"

    func color() -> Color {
        switch self {
        case .investment:
            return .purple
        case .projection:
            return .blue
        case .difference:
            return .green
        case .settings:
            return .orange
        }
    }
}

struct MainTabView: View {
    @AppStorage("com.fromto.selectedTab") private var selectedTab: AppTab = .investment

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.investment) {
                InvestmentListView(tab: .investment)
            } label: {
                Label("Investment", systemImage: "chart.line.uptrend.xyaxis")
            }

            Tab(value: AppTab.projection) {
                ProjectionListView(tab: .projection)
            } label: {
                Label("Projection", systemImage: "chart.bar.doc.horizontal")
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
}
