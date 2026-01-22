//
//  DatabaseManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

/// Centralized database management for Itinero app
/// Uses SwiftData - the best database solution for SwiftUI
@MainActor
class DatabaseManager {
    static let shared = DatabaseManager()
    
    private(set) var container: ModelContainer?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            // Define all models
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
                TripDocument.self
            ])
            
            // Get database location
            guard let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw NSError(domain: "DatabaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access Application Support directory"])
            }
            
            let databaseDirectory = appSupport.appendingPathComponent("Itinero", isDirectory: true)
            
            // Create directory if needed
            try? FileManager.default.createDirectory(
                at: databaseDirectory,
                withIntermediateDirectories: true
            )
            
            let databaseURL = databaseDirectory.appendingPathComponent("default.store")
            
            // Configure persistent storage
            let configuration = ModelConfiguration(
                schema: schema,
                url: databaseURL,
                allowsSave: true,
                cloudKitDatabase: .none // Local storage
            )
            
            // Create container
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            print("✅ SwiftData database initialized at: \(databaseURL.path)")
            
        } catch {
            print("❌ Database setup failed: \(error)")
            // Fallback to in-memory for development
            do {
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
                container = try ModelContainer(for: schema)
                print("⚠️ Using in-memory database as fallback")
            } catch {
                print("❌ Critical: Failed to create even in-memory database: \(error)")
                // Don't crash - return nil and let the app handle it gracefully
                container = nil
            }
        }
    }
    
    /// Get the main context for database operations
    var mainContext: ModelContext? {
        return container?.mainContext
    }
    
    /// Save changes to database
    func save() throws {
        try mainContext?.save()
    }
    
    /// Get database file size
    func databaseSize() -> Int64? {
        guard let url = container?.configurations.first?.url else { return nil }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int64
    }
    
    /// Get database location
    var databaseLocation: String? {
        guard let config = container?.configurations.first else { return nil }
        return config.url.path
    }
}

