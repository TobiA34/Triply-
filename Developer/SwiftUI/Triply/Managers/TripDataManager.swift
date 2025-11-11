//
//  TripDataManager.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData

@MainActor
class TripDataManager: ObservableObject {
    static let shared = TripDataManager()
    
    var modelContainer: ModelContainer?
    
    // Get the database URL in Application Support directory
    private var databaseURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let databaseDirectory = appSupport.appendingPathComponent("Triply")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: databaseDirectory, withIntermediateDirectories: true)
        
        return databaseDirectory.appendingPathComponent("Triply.sqlite")
    }
    
    init() {
        do {
            let schema = Schema([
                TripModel.self,
                DestinationModel.self,
                ItineraryItem.self,
                PackingItem.self,
                Expense.self,
                AppSettings.self
            ])
            
            // Use centralized database manager if available
            if let dbContainer = DatabaseManager.shared.container {
                modelContainer = dbContainer
            } else if let dbURL = databaseURL {
                // Configure SwiftData with persistent storage
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: dbURL,
                    allowsSave: true,
                    cloudKitDatabase: .none // Local storage only for now
                )
                
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } else {
                // Fallback to in-memory if we can't get database URL
                modelContainer = try ModelContainer(for: schema)
            }
            
            // Sample data is now optional - only load if user explicitly wants it
            // Users can start with empty app and add their own trips
            // Uncomment below to enable sample data on first launch:
            /*
            if let container = modelContainer {
                let context = container.mainContext
                let descriptor = FetchDescriptor<TripModel>()
                let trips = try? context.fetch(descriptor)
                if trips?.isEmpty ?? true {
                    loadSampleData(context: context)
                }
            }
            */
        } catch {
            print("Failed to create ModelContainer: \(error)")
            // Fallback to in-memory if persistent storage fails
            do {
                let schema = Schema([
                    TripModel.self,
                    DestinationModel.self,
                    ItineraryItem.self,
                    PackingItem.self,
                    Expense.self,
                    AppSettings.self
                ])
                modelContainer = try ModelContainer(for: schema)
            } catch {
                print("Failed to create fallback container: \(error)")
            }
        }
    }
    
    private func loadSampleData(context: ModelContext) {
        let sampleTrip = TripModel(
            name: "Summer Europe Adventure",
            startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
            notes: "First time in Europe!",
            category: "Adventure",
            budget: 5000.0
        )
        
        let paris = DestinationModel(name: "Paris", address: "Paris, France", notes: "Visit Eiffel Tower", order: 0)
        let rome = DestinationModel(name: "Rome", address: "Rome, Italy", notes: "Colosseum tour", order: 1)
        let barcelona = DestinationModel(name: "Barcelona", address: "Barcelona, Spain", notes: "Sagrada Familia", order: 2)
        
        sampleTrip.destinations?.append(contentsOf: [paris, rome, barcelona])
        context.insert(sampleTrip)
        
        // Add another sample trip
        let weekendTrip = TripModel(
            name: "Weekend Getaway",
            startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 9, to: Date()) ?? Date(),
            notes: "Quick escape to the mountains",
            category: "Relaxation",
            budget: 800.0
        )
        context.insert(weekendTrip)
        
        do {
            try context.save()
        } catch {
            print("Failed to save sample data: \(error)")
        }
    }
}

