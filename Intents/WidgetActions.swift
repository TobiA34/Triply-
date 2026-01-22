//
//  WidgetActions.swift
//  Itinero
//
//  Interactive Widget Actions (iOS 17+)
//

import AppIntents
import Foundation

// MARK: - Open Trip Action
@available(iOS 17.0, *)
struct OpenTripAction: AppIntent {
    static var title: LocalizedStringResource = "Open Trip"
    static var description = IntentDescription("Open this trip in Triply")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip ID")
    var tripId: String
    
    func perform() async throws -> some IntentResult {
        // Navigate to trip via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTrip"),
            object: nil,
            userInfo: ["tripId": tripId]
        )
        return .result()
    }
}

// MARK: - Quick Add Expense Action
@available(iOS 17.0, *)
struct QuickAddExpenseAction: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Quickly add an expense to this trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip ID")
    var tripId: String
    
    @Parameter(title: "Amount")
    var amount: Double
    
    func perform() async throws -> some IntentResult {
        // Show add expense view via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowAddExpense"),
            object: nil,
            userInfo: ["tripId": tripId, "amount": amount]
        )
        return .result()
    }
}

// MARK: - View Itinerary Action
@available(iOS 17.0, *)
struct ViewItineraryAction: AppIntent {
    static var title: LocalizedStringResource = "View Itinerary"
    static var description = IntentDescription("View the itinerary for this trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip ID")
    var tripId: String
    
    func perform() async throws -> some IntentResult {
        // Navigate to trip and open itinerary tab via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTrip"),
            object: nil,
            userInfo: ["tripId": tripId]
        )
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenTripItinerary"),
            object: nil,
            userInfo: ["tripId": tripId]
        )
        return .result()
    }
}
