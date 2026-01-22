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
    @State private var showPermissionRequest = false
    @StateObject private var permissionManager = PermissionRequestManager.shared
    
    var body: some View {
        MainTabView()
            .onAppear {
                // Check if first launch (fast, synchronous)
                let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
                let hasRequestedPermissions = UserDefaults.standard.bool(forKey: "hasRequestedPermissions")
                
                if !hasSeenOnboarding {
                    // Show onboarding first
                    showOnboarding = true
                    UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
                } else if !hasRequestedPermissions {
                    // Then show permission request
                    showPermissionRequest = true
                }
                
                // Load settings asynchronously (non-blocking)
                Task {
                    settingsManager.createDefaultSettings(in: modelContext)
                    settingsManager.loadSettings(from: modelContext)
                }
            }
            .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
                // Refresh view when language changes
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                // Also listen to notification for language changes
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
            .id(refreshID) // Force view refresh on language change
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
                    .onDisappear {
                        // After onboarding, check if we need to request permissions
                        if !UserDefaults.standard.bool(forKey: "hasRequestedPermissions") {
                            showPermissionRequest = true
                        }
                    }
            }
            .fullScreenCover(isPresented: $showPermissionRequest) {
                PermissionRequestView {
                    // Mark permissions as requested and dismiss
                    UserDefaults.standard.set(true, forKey: "hasRequestedPermissions")
                    showPermissionRequest = false
                }
            }
            .refreshOnLanguageChange() // Ensure language changes propagate
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
}

