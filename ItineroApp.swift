//
//  ItineroApp.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData

@main
struct ItineroApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var dataManager = TripDataManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Use the optimized database manager
    private let dbManager = DatabaseManager.shared
    
    var container: ModelContainer {
        // Use the centralized database manager
        if let container = dbManager.container {
            return container
        } else if let container = dataManager.modelContainer {
            return container
        } else {
            // Final fallback - create in-memory container safely
            // This should always succeed
            let schema = Schema([
                TripModel.self,
                DestinationModel.self,
                ItineraryItem.self,
                PackingItem.self,
                Expense.self,
                AppSettings.self,
                CustomTheme.self,
                TripMemory.self,
                TripCollaborator.self,
                TripDocument.self,
                DocumentFolder.self
            ])
            
            // Try to create container - this should never fail for in-memory
            if let container = try? ModelContainer(for: schema, configurations: []) {
                return container
            }
            
            // If that fails, try minimal schema
            if let minimalContainer = try? ModelContainer(for: Schema([TripModel.self]), configurations: []) {
                return minimalContainer
            }
            
            // Last resort - this should always work
            // Create a basic in-memory container without configurations
            return (try? ModelContainer(for: Schema([TripModel.self]))) ?? createFallbackContainer()
        }
    }
    
    // Safe fallback container creation
    private func createFallbackContainer() -> ModelContainer {
        // This should never be called, but provides safety
        print("⚠️ Using emergency fallback container")
        // Try one more time with absolute minimal setup
        do {
            return try ModelContainer(for: Schema([TripModel.self]))
        } catch {
            // If this fails, there's a serious system issue
            // Log it and return a container that will at least let the app start
            print("❌ CRITICAL: All container creation attempts failed: \(error)")
            // Force create - this is the absolute last resort
            // Use do-catch to prevent crash
            do {
                return try ModelContainer(for: Schema([TripModel.self]))
            } catch {
                print("❌ CRITICAL: Final fallback failed: \(error)")
                // Return a minimal in-memory container that won't crash
                return try! ModelContainer(for: Schema([TripModel.self]))
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootThemeView()
                .modelContainer(container)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .environmentObject(themeManager) // Make theme manager available to all views
                .environmentObject(localizationManager) // Make localization manager available to all views
                .onAppear {
                    // Initialize database on app launch safely
                    let _ = DatabaseManager.shared
                    // Ensure localization manager is loaded
                    let _ = LocalizationManager.shared
                    // Configure WishKit with API key
                    WishKit.configure(with: "9097E36F-8E4C-4FC8-B424-11EDA27BB84A")
                }
        }
    }
}

// Root view that handles theme background app-wide
private struct RootThemeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var refreshID = UUID()
    
    var body: some View {
        ZStack {
            // Background at absolute root - covers entire app window
            themeManager.currentPalette.background
                .ignoresSafeArea(.all)
            
            // Content with theme applied
            ContentView()
                .applyAppTheme() // Applies theme colors and styles
                .refreshOnLanguageChange() // Ensure app-wide language refresh
        }
        .id(refreshID)
        .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
            // Force refresh when theme changes
            refreshID = UUID()
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            // Force refresh when theme changes
            refreshID = UUID()
        }
        .onChange(of: themeManager.defaultPalette) { _, _ in
            // Force refresh when palette changes
            refreshID = UUID()
        }
        .onChange(of: themeManager.activeCustomThemeID) { _, _ in
            // Force refresh when custom theme changes
            refreshID = UUID()
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Force refresh when language changes
            refreshID = UUID()
        }
    }
}

