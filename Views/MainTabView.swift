//
//  MainTabView.swift
//  Itinero
//
//  Main tab bar navigation for the app
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @Query(sort: \TripModel.startDate, order: .forward) private var trips: [TripModel]
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Trips Tab
            NavigationStack {
                TripListView()
            }
            .tabItem {
                Label("Trips", systemImage: "airplane")
            }
            .tag(0)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(1)
        }
        .accentColor(themeManager.currentPalette.accent)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
        .environmentObject(ThemeManager.shared)
}
