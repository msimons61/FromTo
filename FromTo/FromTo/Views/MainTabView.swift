//
//  MainTabView.swift
//  FromTo
//
//  Created by Claude Code on 12-01-2026.
//

import SwiftUI

enum Tab: Int {
    case investment = 0
    case difference = 1
    case settings = 2
}

struct MainTabView: View {
    @EnvironmentObject var settings: SettingsData
    @AppStorage("com.fromto.selectedTab") private var selectedTab: Int = Tab.investment.rawValue

    var body: some View {
        TabView(selection: $selectedTab) {
            InvestmentView(settings: settings)
                .tabItem {
                    Label("Investment", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.investment.rawValue)

            DifferenceView()
                .tabItem {
                    Label("Difference", systemImage: "arrow.left.arrow.right")
                }
                .tag(Tab.difference.rawValue)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings.rawValue)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SettingsData())
}
