//
//  ContentView.swift
//  DF868w
//
//  Ledgerly - Main tab navigation
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AppStore.self) private var store
    @Query private var preferences: [Preferences]

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch preferences.first?.themeChoice ?? .system {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppStore(modelContext: ModelContainer.preview.mainContext))
        .modelContainer(ModelContainer.preview)
}
