//
//  TriplyApp.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

@main
struct TriplyApp: App {
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
                CustomTheme.self
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
            return try! ModelContainer(for: Schema([TripModel.self]))
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .applyAppTheme()
                .onAppear {
                    // Initialize database on app launch safely
                    let _ = DatabaseManager.shared
                    // Ensure localization manager is loaded
                    let _ = LocalizationManager.shared
                    // Refresh IAP entitlements
                    Task {
                        await IAPManager.shared.refreshEntitlements()
                        IAPManager.shared.observeTransactions()
                    }
                }
        }
    }
}

