//
//  ShortcutsIntegration.swift
//  Itinero
//
//  iOS 18+ Shortcuts App Integration - Create automations for trips
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Get Active Trip Action
@available(iOS 18.0, *)
struct GetActiveTripAction: AppIntent {
    static var title: LocalizedStringResource = "Get Active Trip"
    static var description = IntentDescription("Get your currently active trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some ReturnsValue<TripInfo?> {
        if let activeTrip = TripDataAccessor.getActiveTrip() {
            return .result(value: TripInfo(from: activeTrip))
        }
        
        return .result(value: nil)
    }
}

// MARK: - Get Upcoming Trip Action
@available(iOS 18.0, *)
struct GetUpcomingTripAction: AppIntent {
    static var title: LocalizedStringResource = "Get Upcoming Trip"
    static var description = IntentDescription("Get your next upcoming trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some ReturnsValue<TripInfo?> {
        if let upcomingTrip = TripDataAccessor.getUpcomingTrip() {
            return .result(value: TripInfo(from: upcomingTrip))
        }
        
        return .result(value: nil)
    }
}

// MARK: - Get Trip Countdown Action
@available(iOS 18.0, *)
struct GetTripCountdownAction: AppIntent {
    static var title: LocalizedStringResource = "Get Trip Countdown"
    static var description = IntentDescription("Get days until your next trip")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Trip Name")
    var tripName: String?
    
    func perform() async throws -> some ReturnsValue<Int> {
        let now = Date()
        let targetTrip: TripModel?
        
        if let tripName = tripName {
            targetTrip = TripDataAccessor.getTrip(byName: tripName)
        } else {
            targetTrip = TripDataAccessor.getUpcomingTrip()
        }
        
        guard let trip = targetTrip, trip.startDate > now else {
            return .result(value: 0)
        }
        
        let days = Calendar.current.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
        return .result(value: days)
    }
}

// MARK: - Add Expense to Trip Action
@available(iOS 18.0, *)
struct AddExpenseToTripAction: AppIntent {
    static var title: LocalizedStringResource = "Add Expense to Trip"
    static var description = IntentDescription("Add an expense to a trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip Name")
    var tripName: String
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String?
    
    @Parameter(title: "Description")
    var description: String?
    
    func perform() async throws -> some IntentResult {
        // Post notification to add expense
        NotificationCenter.default.post(
            name: NSNotification.Name("AddExpenseToTrip"),
            object: nil,
            userInfo: [
                "tripName": tripName,
                "amount": amount,
                "category": category ?? "General",
                "description": description ?? ""
            ]
        )
        return .result()
    }
}

// MARK: - Trip Info Value Type
@available(iOS 18.0, *)
struct TripInfo: Codable, AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Trip Info")
    static var defaultQuery = TripInfoQuery()
    
    var id: UUID
    var name: String
    var destination: String?
    var startDate: Date
    var endDate: Date
    var daysUntil: Int
    var isActive: Bool
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: destination ?? "Trip")
        )
    }
    
    init(from trip: TripModel) {
        self.id = trip.id
        self.name = trip.name
        self.destination = trip.destinations?.first?.name
        self.startDate = trip.startDate
        self.endDate = trip.endDate
        
        let now = Date()
        if trip.startDate > now {
            self.daysUntil = Calendar.current.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
            self.isActive = false
        } else if trip.endDate >= now {
            self.daysUntil = 0
            self.isActive = true
        } else {
            self.daysUntil = 0
            self.isActive = false
        }
    }
}

// MARK: - Trip Info Query (required for AppEntity)
@available(iOS 18.0, *)
struct TripInfoQuery: EntityQuery {
    func entities(for identifiers: [TripInfo.ID]) async throws -> [TripInfo] {
        // TripInfo is a return value, not a selectable entity
        // Return empty array as it's not meant to be queried
        return []
    }
    
    func suggestedEntities() async throws -> [TripInfo] {
        // Return empty array as TripInfo is not meant to be suggested
        return []
    }
}


//  Itinero
//
//  iOS 18+ Shortcuts App Integration - Create automations for trips
//

import AppIntents
import Foundation
import SwiftData

//  Itinero
//
//  iOS 18+ Shortcuts App Integration - Create automations for trips
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Get Active Trip Action
@available(iOS 18.0, *)
struct GetActiveTripAction: AppIntent {
    static var title: LocalizedStringResource = "Get Active Trip"
    static var description = IntentDescription("Get your currently active trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some ReturnsValue<TripInfo?> {
        if let activeTrip = TripDataAccessor.getActiveTrip() {
            return .result(value: TripInfo(from: activeTrip))
        }
        
        return .result(value: nil)
    }
}

// MARK: - Get Upcoming Trip Action
@available(iOS 18.0, *)
struct GetUpcomingTripAction: AppIntent {
    static var title: LocalizedStringResource = "Get Upcoming Trip"
    static var description = IntentDescription("Get your next upcoming trip")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some ReturnsValue<TripInfo?> {
        if let upcomingTrip = TripDataAccessor.getUpcomingTrip() {
            return .result(value: TripInfo(from: upcomingTrip))
        }
        
        return .result(value: nil)
    }
}

// MARK: - Get Trip Countdown Action
@available(iOS 18.0, *)
struct GetTripCountdownAction: AppIntent {
    static var title: LocalizedStringResource = "Get Trip Countdown"
    static var description = IntentDescription("Get days until your next trip")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Trip Name")
    var tripName: String?
    
    func perform() async throws -> some ReturnsValue<Int> {
        let now = Date()
        let targetTrip: TripModel?
        
        if let tripName = tripName {
            targetTrip = TripDataAccessor.getTrip(byName: tripName)
        } else {
            targetTrip = TripDataAccessor.getUpcomingTrip()
        }
        
        guard let trip = targetTrip, trip.startDate > now else {
            return .result(value: 0)
        }
        
        let days = Calendar.current.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
        return .result(value: days)
    }
}

// MARK: - Add Expense to Trip Action
@available(iOS 18.0, *)
struct AddExpenseToTripAction: AppIntent {
    static var title: LocalizedStringResource = "Add Expense to Trip"
    static var description = IntentDescription("Add an expense to a trip")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip Name")
    var tripName: String
    
    @Parameter(title: "Amount")
    var amount: Double
    
    @Parameter(title: "Category")
    var category: String?
    
    @Parameter(title: "Description")
    var description: String?
    
    func perform() async throws -> some IntentResult {
        // Post notification to add expense
        NotificationCenter.default.post(
            name: NSNotification.Name("AddExpenseToTrip"),
            object: nil,
            userInfo: [
                "tripName": tripName,
                "amount": amount,
                "category": category ?? "General",
                "description": description ?? ""
            ]
        )
        return .result()
    }
}

// MARK: - Trip Info Value Type
@available(iOS 18.0, *)
// MARK: - TripInfo (DUPLICATE - REMOVED)
// struct TripInfo: Codable, AppEntity {
//     static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Trip Info")
//     static var defaultQuery = TripInfoQuery()
    
//     var id: UUID
//     var name: String
//     var destination: String?
//     var startDate: Date
//     var endDate: Date
//     var daysUntil: Int
//     var isActive: Bool
    
//     var displayRepresentation: DisplayRepresentation {
//         DisplayRepresentation(
//             title: LocalizedStringResource(stringLiteral: name),
//             subtitle: LocalizedStringResource(stringLiteral: destination ?? "Trip")
//         )
//     }
    
//     init(from trip: TripModel) {
//         self.id = trip.id
//         self.name = trip.name
//         self.destination = trip.destinations?.first?.name
//         self.startDate = trip.startDate
//         self.endDate = trip.endDate
        
//         let now = Date()
//         if trip.startDate > now {
//             self.daysUntil = Calendar.current.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
//             self.isActive = false
//         } else if trip.endDate >= now {
//             self.daysUntil = 0
//             self.isActive = true
//         } else {
//             self.daysUntil = 0
//             self.isActive = false
//         }
//     }
// }

// MARK: - Trip Info Query (DUPLICATE - REMOVED)
// MARK: - TripInfoQuery (DUPLICATE - REMOVED)
// Commented out to avoid redeclaration error
// /*
// struct TripInfoQuery: EntityQuery {
//     func entities(for identifiers: [TripInfo.ID]) async throws -> [TripInfo] {
        // TripInfo is a return value, not a selectable entity
        // Return empty array as it's not meant to be queried
//         return []
//     }
    
//     func suggestedEntities() async throws -> [TripInfo] {
        // Return empty array as TripInfo is not meant to be suggested
//         return []
//     }
// }


//  Itinero
//
//  iOS 18+ Shortcuts App Integration - Create automations for trips
//

import AppIntents
import Foundation
import SwiftData
