//
//  ContentView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            TripListView()
                .onAppear {
                    // Ensure default settings exist
                    settingsManager.createDefaultSettings(in: modelContext)
                    // Load settings
                    settingsManager.loadSettings(from: modelContext)
                }
                .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
                    // Refresh view when language changes
                    refreshID = UUID()
                }
                .id(refreshID) // Force view refresh on language change
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
}

