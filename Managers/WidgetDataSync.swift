//
//  WidgetDataSync.swift
//  Itinero
//
//  Alternative data sharing for widgets using UserDefaults + App Groups
//  This works even if SwiftData App Groups isn't fully configured
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
class WidgetDataSync: ObservableObject {
    static let shared = WidgetDataSync()
    
    private let appGroupIdentifier = "group.com.ntriply.app"
    private let userDefaults: UserDefaults?
    private let sharedFileURL: URL?
    
    private init() {
        // Try to access App Group UserDefaults first
        self.userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        // Fallback: Use shared file location that both app and widget can access
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            // App Groups available - use it
            self.sharedFileURL = appGroupURL.appendingPathComponent("widget_data.json")
            print("✅ WidgetDataSync: App Groups UserDefaults accessible")
        } else {
            // App Groups not available - use Application Support (widgets can't access this, but we'll try file-based)
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let widgetDataDir = appSupport.appendingPathComponent("WidgetData", isDirectory: true)
                try? FileManager.default.createDirectory(at: widgetDataDir, withIntermediateDirectories: true)
                self.sharedFileURL = widgetDataDir.appendingPathComponent("widget_data.json")
                print("⚠️ WidgetDataSync: App Groups not configured, using file-based sync")
            } else {
                self.sharedFileURL = nil
                print("❌ WidgetDataSync: Cannot create shared file location")
            }
        }
    }
    
    // MARK: - Trip Data Sync
    
    /// Sync trip data for widget access (tries UserDefaults first, then file-based)
    func syncTrips(_ trips: [TripModel]) {
        // Convert trips to simple dictionary format
        let tripData = trips.map { trip in
            [
                "id": trip.id.uuidString,
                "name": trip.name,
                "destination": trip.destinations?.first?.name ?? "No destination",
                "startDate": trip.startDate.timeIntervalSince1970,
                "endDate": trip.endDate.timeIntervalSince1970,
                "budget": trip.budget ?? 0.0,
                "category": trip.category,
                "duration": trip.duration
            ] as [String: Any]
        }
        
        // Calculate expenses
        let tripsWithExpenses = trips.map { trip -> [String: Any] in
            let totalExpenses = trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0
            return [
                "id": trip.id.uuidString,
                "totalExpenses": totalExpenses
            ]
        }
        
        let syncData: [String: Any] = [
            "trips": tripData,
            "expenses": tripsWithExpenses,
            "lastSync": Date().timeIntervalSince1970
        ]
        
        // Try UserDefaults first (if App Groups available)
        if let userDefaults = userDefaults {
            userDefaults.set(tripData, forKey: "widget_trips")
            userDefaults.set(tripsWithExpenses, forKey: "widget_expenses")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "widget_last_sync")
            userDefaults.synchronize()
            print("✅ WidgetDataSync: Synced \(trips.count) trips to UserDefaults")
        }
        
        // Always try to write to App Group container file (even if UserDefaults failed)
        // This ensures widgets can access data if App Groups is configured
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let appGroupFile = appGroupURL.appendingPathComponent("widget_data.json")
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: syncData, options: .prettyPrinted)
                try jsonData.write(to: appGroupFile, options: .atomic)
                print("✅ WidgetDataSync: Synced \(trips.count) trips to App Group file")
            } catch {
                // Silent fail - widgets will use UserDefaults if available
            }
        }
        
        // Also write to local backup file
        if let fileURL = sharedFileURL {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: syncData, options: .prettyPrinted)
                try jsonData.write(to: fileURL, options: .atomic)
            } catch {
                // Silent fail
            }
        }
    }
    
    /// Load trips from UserDefaults or file (for widgets)
    static func loadTripsFromUserDefaults() -> [[String: Any]] {
        // Try UserDefaults first (App Groups)
        if let userDefaults = UserDefaults(suiteName: "group.com.ntriply.app"),
           let trips = userDefaults.array(forKey: "widget_trips") as? [[String: Any]],
           !trips.isEmpty {
            print("✅ WidgetDataSync: Loaded \(trips.count) trips from UserDefaults")
            return trips
        }
        
        // Try file-based (works even without App Groups if in shared location)
        let appGroupIdentifier = "group.com.ntriply.app"
        var fileURL: URL?
        
        // Try App Group container first
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            fileURL = appGroupURL.appendingPathComponent("widget_data.json")
        } else {
            // Fallback to Application Support (widgets can't access this, but try anyway)
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                fileURL = appSupport.appendingPathComponent("WidgetData/widget_data.json")
            }
        }
        
        if let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let trips = json["trips"] as? [[String: Any]] {
                    print("✅ WidgetDataSync: Loaded \(trips.count) trips from file")
                    return trips
                }
            } catch {
                print("⚠️ WidgetDataSync: Failed to read file: \(error.localizedDescription)")
            }
        }
        
        print("⚠️ WidgetDataSync: No trips found in UserDefaults or file")
        return []
    }
    
    /// Load expenses from UserDefaults or file (for widgets)
    static func loadExpensesFromUserDefaults() -> [String: Double] {
        // Try UserDefaults first
        if let userDefaults = UserDefaults(suiteName: "group.com.ntriply.app"),
           let expenses = userDefaults.array(forKey: "widget_expenses") as? [[String: Any]] {
            var expenseDict: [String: Double] = [:]
            for expense in expenses {
                if let id = expense["id"] as? String,
                   let total = expense["totalExpenses"] as? Double {
                    expenseDict[id] = total
                }
            }
            return expenseDict
        }
        
        // Try file-based
        let appGroupIdentifier = "group.com.ntriply.app"
        var fileURL: URL?
        
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            fileURL = appGroupURL.appendingPathComponent("widget_data.json")
        } else if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            fileURL = appSupport.appendingPathComponent("WidgetData/widget_data.json")
        }
        
        if let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let expenses = json["expenses"] as? [[String: Any]] {
                    var expenseDict: [String: Double] = [:]
                    for expense in expenses {
                        if let id = expense["id"] as? String,
                           let total = expense["totalExpenses"] as? Double {
                            expenseDict[id] = total
                        }
                    }
                    return expenseDict
                }
            } catch {
                // Ignore file read errors
            }
        }
        
        return [:]
    }
    
    /// Get last sync time
    static func lastSyncTime() -> Date? {
        // Try UserDefaults first
        if let userDefaults = UserDefaults(suiteName: "group.com.ntriply.app"),
           let timestamp = userDefaults.object(forKey: "widget_last_sync") as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        // Try file
        let appGroupIdentifier = "group.com.ntriply.app"
        var fileURL: URL?
        
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            fileURL = appGroupURL.appendingPathComponent("widget_data.json")
        } else if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            fileURL = appSupport.appendingPathComponent("WidgetData/widget_data.json")
        }
        
        if let fileURL = fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let timestamp = json["lastSync"] as? TimeInterval {
                    return Date(timeIntervalSince1970: timestamp)
                }
            } catch {
                // Ignore
            }
        }
        
        return nil
    }
}

