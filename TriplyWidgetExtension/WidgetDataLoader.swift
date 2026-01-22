//
//  WidgetDataLoader.swift
//  Itinero
//
//  Loads trip data from SwiftData for widgets
//

import Foundation
import SwiftData

// Import the TripModel from the widget extension
// Note: TripModel should be available in the widget extension target

struct WidgetDataLoader {
    // App Group identifier - must match the one configured in Xcode
    private static let appGroupIdentifier = "group.com.nitinero.app"
    
    // Get database URL - try App Group first, then fallback to Application Support
    private static var databaseURL: URL? {
        // First, try App Group container (if configured)
        // Note: containerURL doesn't throw, it returns nil if not configured
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let databaseDirectory = appGroupURL.appendingPathComponent("Itinero", isDirectory: true)
            let dbURL = databaseDirectory.appendingPathComponent("default.store")
            
            if FileManager.default.fileExists(atPath: dbURL.path) {
                return dbURL
            }
        }
        
        // Fallback to Application Support (main app's location)
        // Note: This won't work in widget extension's container without App Groups
        // Widget extension has its own isolated container, so it can't access main app's Application Support
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        let databaseDirectory = appSupport.appendingPathComponent("Itinero", isDirectory: true)
        let dbURL = databaseDirectory.appendingPathComponent("default.store")
        
        // Check if file exists before returning
        if FileManager.default.fileExists(atPath: dbURL.path) {
            return dbURL
        }
        
        // No database found - will use fallback (no error)
        return nil
    }
    
    // Create a ModelContainer for widget access
    private static func createContainer() -> ModelContainer? {
        guard let databaseURL = databaseURL else {
            return nil
        }
        
        // Verify file exists and is readable
        guard FileManager.default.fileExists(atPath: databaseURL.path),
              FileManager.default.isReadableFile(atPath: databaseURL.path) else {
            return nil
        }
        
        do {
            // Use the SAME schema as the main app to avoid schema mismatch errors
            // Widget must include all models that are in the database, even if not used
            // Only include models that are available in the widget extension target
            let schema = Schema([
                TripModel.self,
                DestinationModel.self,
                ItineraryItem.self,
                PackingItem.self,
                Expense.self,
                DocumentFolder.self
            ])
            
            // Widgets are read-only, so we need to open the database in read-only mode
            // SwiftData doesn't support read-only mode directly, but we can use allowsSave: false
            let configuration = ModelConfiguration(
                schema: schema,
                url: databaseURL,
                allowsSave: false, // Widgets are read-only - this prevents write operations
                cloudKitDatabase: .none
            )
            
            // Try to create container - if migration is needed, it will fail
            // In that case, we'll return nil and widget shows "No Trip"
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
            
            return container
        } catch {
            // Database load failed - will use fallback (no error message)
            return nil
        }
    }
    
    // Load trips from SwiftData (primary method)
    static func loadTrips() -> [TripModel] {
        // For maximum stability on widgets (and to avoid SwiftData schema / App Group issues),
        // we only read from the pre-synced UserDefaults / JSON data written by WidgetDataSync.
        // This guarantees the widget always returns data or an empty array instead of crashing.
        return loadTripsFromUserDefaultsFallback()
    }
    
    // Fallback: Load trips from UserDefaults or file (works even without App Groups fully configured)
    private static func loadTripsFromUserDefaultsFallback() -> [TripModel] {
        let tripData = WidgetDataLoader.loadTripsFromUserDefaults()
        
        guard !tripData.isEmpty else {
            // Don't print error - this is expected if App Groups isn't configured
            // Widget will show "No Trip" which is acceptable
            return []
        }
        
        // Successfully loaded from fallback
        
        // Convert dictionary data to TripModel-like structure
        // Note: This creates simplified trip data for widgets
        return tripData.compactMap { data -> TripModel? in
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = data["name"] as? String,
                  let startTimestamp = data["startDate"] as? TimeInterval,
                  let endTimestamp = data["endDate"] as? TimeInterval else {
                return nil
            }
            
            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let endDate = Date(timeIntervalSince1970: endTimestamp)
            let destination = data["destination"] as? String ?? "No destination"
            let budget = data["budget"] as? Double ?? 0.0
            let category = data["category"] as? String ?? "Leisure"
            let duration = data["duration"] as? Int ?? 1
            
            // Create a simplified TripModel for widget use
            let trip = TripModel(
                id: id,
                name: name,
                startDate: startDate,
                endDate: endDate,
                notes: "",
                category: category,
                budget: budget
            )
            // Note: duration is computed from startDate/endDate, no need to set it
            
            // Add destination
            let dest = DestinationModel(name: destination)
            trip.destinations = [dest]
            
            return trip
        }
    }
    
    // Load trips from UserDefaults or file (public method for widgets)
    static func loadTripsFromUserDefaults() -> [[String: Any]] {
        // Try UserDefaults first (App Groups)
        if let userDefaults = UserDefaults(suiteName: "group.com.nitinero.app"),
           let trips = userDefaults.array(forKey: "widget_trips") as? [[String: Any]],
           !trips.isEmpty {
            return trips
        }
        
        // Try file-based (works even without App Groups if in shared location)
        let appGroupIdentifier = "group.com.nitinero.app"
        var fileURL: URL?
        
        // Try App Group container first
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            fileURL = appGroupURL.appendingPathComponent("widget_data.json")
        } else if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            fileURL = appSupport.appendingPathComponent("WidgetData/widget_data.json")
        }
        
        if let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let trips = json["trips"] as? [[String: Any]] {
                    return trips
                }
            } catch {
                // Silent fail
            }
        } else {
            // File doesn't exist - this is expected if App Groups isn't configured
            // Don't print error, just return empty array
        }
        
        // No trips found - this is acceptable, widget will show "No Trip"
        return []
    }
    
    // Get the next upcoming trip
    static func getUpcomingTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate > now
        }
    }
    
    // Get the currently active trip
    static func getActiveTrip() -> TripModel? {
        let trips = loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate <= now && trip.endDate >= now
        }
    }
    
    // Get trip by ID
    static func getTrip(id: UUID) -> TripModel? {
        let trips = loadTrips()
        return trips.first { $0.id == id }
    }
    
    // Convert TripModel to TripWidgetData
    static func convertToWidgetData(_ trip: TripModel) -> TripWidgetData {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate days until or current day
        let daysUntil: Int
        let isActive: Bool
        let currentDay: Int?
        
        if trip.startDate > now {
            // Upcoming
            daysUntil = calendar.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
            isActive = false
            currentDay = nil
        } else if trip.endDate >= now {
            // Active
            daysUntil = 0
            isActive = true
            currentDay = calendar.dateComponents([.day], from: trip.startDate, to: now).day ?? 0
        } else {
            // Past
            daysUntil = 0
            isActive = false
            currentDay = nil
        }
        
        // Calculate total expenses
        let totalExpenses = trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0
        
        // Get primary destination
        let destination = trip.destinations?.first?.name ?? "No destination"
        
        return TripWidgetData(
            id: trip.id,
            name: trip.name,
            destination: destination,
            startDate: trip.startDate,
            endDate: trip.endDate,
            daysUntil: daysUntil,
            isActive: isActive,
            currentDay: currentDay,
            totalDays: trip.duration,
            budget: trip.budget,
            totalExpenses: totalExpenses,
            category: trip.category,
            coverImageData: trip.coverImageData
        )
    }
}
