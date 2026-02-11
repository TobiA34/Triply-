//
//  ContentView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var refreshID = UUID()
    
    @State private var showOnboarding = false
    
    var body: some View {
        MainTabView()
            .onAppear {
                // Check if first launch (fast, synchronous)
                let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
                
                // Defer state updates to avoid publishing during view updates
                Task { @MainActor in
                    if !hasSeenOnboarding {
                        showOnboarding = true
                        UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
                    }
                }
                
                // Load settings asynchronously (non-blocking)
                Task {
                    settingsManager.createDefaultSettings(in: modelContext)
                    settingsManager.loadSettings(from: modelContext)
                }
            }
            .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        refreshID = UUID()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        refreshID = UUID()
                    }
                }
            }
            .id(refreshID)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .refreshOnLanguageChange()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
}

