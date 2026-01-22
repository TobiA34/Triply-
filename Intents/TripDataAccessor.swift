//
//  TripDataAccessor.swift
//  Itinero
//
//  Shared data accessor for App Intents
//

import Foundation
import SwiftData

// Note: TripModel needs to be accessible from App Intents
// This file should be included in both main app and intents target

@available(iOS 18.0, *)
struct TripDataAccessor {
    // Create a ModelContainer for App Intents
    // App Intents run in a separate process and need their own container
    private static func createContainer() -> ModelContainer? {
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
        
        // Try to use App Group container (same as main app)
        let appGroupIdentifier = "group.com.nitinero.app"
        var databaseURL: URL?
        
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseDirectory = appGroupURL.appendingPathComponent("Itinero", isDirectory: true)
            databaseURL = databaseDirectory.appendingPathComponent("default.store")
        } else {
            // Fallback to Application Support
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let databaseDirectory = appSupport.appendingPathComponent("Itinero", isDirectory: true)
                databaseURL = databaseDirectory.appendingPathComponent("default.store")
            }
        }
        
        guard let dbURL = databaseURL, FileManager.default.fileExists(atPath: dbURL.path) else {
            return nil
        }
        
        let configuration = ModelConfiguration(
            schema: schema,
            url: dbURL,
            allowsSave: false, // App Intents are read-only
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            return nil
        }
    }
    
    // Load trips from SwiftData for App Intents
    static func loadTrips() -> [TripModel] {
        guard let container = createContainer() else {
            return []
        }
        
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TripModel>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    static func getActiveTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate <= now && trip.endDate >= now
        }
    }
    
    static func getUpcomingTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips
            .filter { $0.startDate > now }
            .sorted(by: { $0.startDate < $1.startDate })
            .first
    }
    
    static func getTrip(byName name: String) -> TripModel? {
        let trips = loadTrips()
        return trips.first { $0.name.localizedCaseInsensitiveContains(name) }
    }
}


//  Itinero
//
//  Shared data accessor for App Intents
//

import Foundation
import SwiftData

//  Itinero
//
//  Shared data accessor for App Intents
//

import Foundation
import SwiftData

// Note: TripModel needs to be accessible from App Intents
// This file should be included in both main app and intents target

@available(iOS 18.0, *)
struct TripDataAccessor {
    // Create a ModelContainer for App Intents
    // App Intents run in a separate process and need their own container
    private static func createContainer() -> ModelContainer? {
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
        
        // Try to use App Group container (same as main app)
        let appGroupIdentifier = "group.com.nitinero.app"
        var databaseURL: URL?
        
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseDirectory = appGroupURL.appendingPathComponent("Itinero", isDirectory: true)
            databaseURL = databaseDirectory.appendingPathComponent("default.store")
        } else {
            // Fallback to Application Support
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let databaseDirectory = appSupport.appendingPathComponent("Itinero", isDirectory: true)
                databaseURL = databaseDirectory.appendingPathComponent("default.store")
            }
        }
        
        guard let dbURL = databaseURL, FileManager.default.fileExists(atPath: dbURL.path) else {
            return nil
        }
        
        let configuration = ModelConfiguration(
            schema: schema,
            url: dbURL,
            allowsSave: false, // App Intents are read-only
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            return nil
        }
    }
    
    // Load trips from SwiftData for App Intents
    static func loadTrips() -> [TripModel] {
        guard let container = createContainer() else {
            return []
        }
        
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<TripModel>(
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    static func getActiveTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate <= now && trip.endDate >= now
        }
    }
    
    static func getUpcomingTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips
            .filter { $0.startDate > now }
            .sorted(by: { $0.startDate < $1.startDate })
            .first
    }
    
    static func getTrip(byName name: String) -> TripModel? {
        let trips = loadTrips()
        return trips.first { $0.name.localizedCaseInsensitiveContains(name) }
    }
}


//  Itinero
//
//  Shared data accessor for App Intents
//

import Foundation
import SwiftData
