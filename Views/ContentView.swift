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
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var refreshID = UUID()

    @State private var showOnboarding = false
    @State private var showPostOnboardingPaywall = false
    
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
            .onChange(of: showOnboarding) { oldValue, newValue in
                // When onboarding dismisses, check if we should show post-onboarding paywall
                if !newValue && oldValue {
                    let hasSeenPaywall = UserDefaults.standard.bool(forKey: "itinero_has_seen_post_onboarding_paywall")
                    if !hasSeenPaywall && !iapManager.isPro {
                        // Show paywall once after onboarding — but only when
                        // packages actually loaded, so new users never see a
                        // configuration error, and keep the one-time flag
                        // unspent otherwise.
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            if await iapManager.preparePaywall() {
                                showPostOnboardingPaywall = true
                                UserDefaults.standard.set(true, forKey: "itinero_has_seen_post_onboarding_paywall")
                            }
                        }
                    }
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
            .sheet(isPresented: $showPostOnboardingPaywall) {
                PaywallView()
            }
            .refreshOnLanguageChange()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
}

