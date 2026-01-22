//
//  TripAppShortcuts.swift
//  Itinero
//
//  iOS 18 App Shortcuts for Spotlight and Siri
//

import AppIntents
import Foundation

// MARK: - Quick Add Trip Shortcut
@available(iOS 18.0, *)
struct QuickAddTripShortcut: AppIntent {
    static var title: LocalizedStringResource = "Quick Add Trip"
    static var description = IntentDescription("Quickly add a new trip to Itinero")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip Name")
    var tripName: String
    
    @Parameter(title: "Destination")
    var destination: String?
    
    func perform() async throws -> some IntentResult {
        // Trigger navigation to add trip view via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddTrip"),
            object: nil
        )
        return .result()
    }
}

// MARK: - View Active Trip Shortcut
@available(iOS 18.0, *)
struct ViewActiveTripShortcut: AppIntent {
    static var title: LocalizedStringResource = "View Active Trip"
    static var description = IntentDescription("Open your currently active trip")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Navigate to active trip via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToActiveTrip"),
            object: nil
        )
        return .result()
    }
}

// MARK: - View Upcoming Trips Shortcut
@available(iOS 18.0, *)
struct ViewUpcomingTripsShortcut: AppIntent {
    static var title: LocalizedStringResource = "View Upcoming Trips"
    static var description = IntentDescription("View your upcoming trips")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Navigate to upcoming trips via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToUpcomingTrips"),
            object: nil
        )
        return .result()
    }
}

// MARK: - Add Expense Shortcut
@available(iOS 18.0, *)
struct QuickAddExpenseShortcut: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Quickly add an expense to your active trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String?
    
    func perform() async throws -> some IntentResult {
        // Show add expense view via notification
        var userInfo: [AnyHashable: Any] = ["amount": amount]
        if let category = category {
            userInfo["category"] = category
        }
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddExpense"),
            object: nil,
            userInfo: userInfo
        )
        return .result()
    }
}

// MARK: - Check Trip Countdown Shortcut
@available(iOS 18.0, *)
struct CheckTripCountdownShortcut: AppIntent {
    static var title: LocalizedStringResource = "Check Trip Countdown"
    static var description = IntentDescription("Check how many days until your next trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Query SwiftData for the next trip
        let daysUntil = await getDaysUntilNextTrip()
        if let days = daysUntil {
            return .result(value: "Your next trip is in \(days) day\(days == 1 ? "" : "s")!")
        } else {
            return .result(value: "You don't have any upcoming trips.")
        }
    }
    
    private func getDaysUntilNextTrip() async -> Int? {
        // This would query SwiftData in production
        // For now, return nil to indicate no trips
        return nil
    }
}

// MARK: - App Shortcuts Provider
@available(iOS 18.0, *)
struct ItineroAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return []
    }
}


//  Itinero
//
//  iOS 18 App Shortcuts for Spotlight and Siri
//

import AppIntents
import Foundation

// MARK: - Quick Add Trip Shortcut
@available(iOS 18.0, *)
// MARK: - Quick Add Trip Shortcut (DUPLICATE - REMOVED)
//     static var title: LocalizedStringResource = "Quick Add Trip"
//     static var description = IntentDescription("Quickly add a new trip to Itinero")
//     static var openAppWhenRun: Bool = true
    
//     @Parameter(title: "Trip Name")
//     var tripName: String
    
//     @Parameter(title: "Destination")
//     var destination: String?
    
//     func perform() async throws -> some IntentResult {
        // Trigger navigation to add trip view via notification
//         NotificationCenter.default.post(
//             name: NSNotification.Name("ShowAddTrip"),
//             object: nil
//         )
//         return .result()
//     }
// }

// MARK: - View Active Trip Shortcut
@available(iOS 18.0, *)
struct ViewActiveTripShortcut: AppIntent {
    static var title: LocalizedStringResource = "View Active Trip"
    static var description = IntentDescription("Open your currently active trip")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Navigate to active trip via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToActiveTrip"),
            object: nil
        )
        return .result()
    }
}

// MARK: - View Upcoming Trips Shortcut
@available(iOS 18.0, *)
struct ViewUpcomingTripsShortcut: AppIntent {
    static var title: LocalizedStringResource = "View Upcoming Trips"
    static var description = IntentDescription("View your upcoming trips")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Navigate to upcoming trips via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToUpcomingTrips"),
            object: nil
        )
        return .result()
    }
}

// MARK: - Add Expense Shortcut
@available(iOS 18.0, *)
struct QuickAddExpenseShortcut: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Quickly add an expense to your active trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String?
    
    func perform() async throws -> some IntentResult {
        // Show add expense view via notification
        var userInfo: [AnyHashable: Any] = ["amount": amount]
        if let category = category {
            userInfo["category"] = category
        }
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddExpense"),
            object: nil,
            userInfo: userInfo
        )
        return .result()
    }
}

// MARK: - Check Trip Countdown Shortcut
@available(iOS 18.0, *)
struct CheckTripCountdownShortcut: AppIntent {
    static var title: LocalizedStringResource = "Check Trip Countdown"
    static var description = IntentDescription("Check how many days until your next trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Query SwiftData for the next trip
        let daysUntil = await getDaysUntilNextTrip()
        if let days = daysUntil {
            return .result(value: "Your next trip is in \(days) day\(days == 1 ? "" : "s")!")
        } else {
            return .result(value: "You don't have any upcoming trips.")
        }
    }
    
    private func getDaysUntilNextTrip() async -> Int? {
        // This would query SwiftData in production
        // For now, return nil to indicate no trips
        return nil
    }
}

// MARK: - App Shortcuts Provider
@available(iOS 18.0, *)
struct ItineroAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return []
    }
}

