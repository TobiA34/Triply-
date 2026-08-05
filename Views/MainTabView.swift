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

    private var tabBackgroundColor: UIColor {
        UIColor(themeManager.currentPalette.background)
    }

    private var watchSyncFingerprint: String {
        trips
            .map { "\($0.id.uuidString)-\($0.lastModified.timeIntervalSince1970)" }
            .joined(separator: "|")
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Trips Tab
            NavigationStack {
                TripListView()
            }
            .tabItem {
                Label("trips.title".localized, systemImage: selectedTab == 0 ? "airplane.circle.fill" : "airplane.circle")
            }
            .tag(0)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("settings.title".localized, systemImage: selectedTab == 1 ? "gearshape.fill" : "gearshape")
            }
            .tag(1)
        }
        .accentColor(themeManager.currentPalette.accent)
        .onAppear {
            configureTabBarAppearance()
            WatchSyncManager.shared.pushTrips(trips)
        }
        .onChange(of: themeManager.currentPalette) { _, _ in
            configureTabBarAppearance()
        }
        .task(id: watchSyncFingerprint) {
            WatchSyncManager.shared.pushTrips(trips)
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = tabBackgroundColor
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.06)

        let selectedColor = UIColor(themeManager.currentPalette.accent)
        let unselectedColor = UIColor(themeManager.currentPalette.secondaryText)

        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: unselectedColor]

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
        .environmentObject(ThemeManager.shared)
}
