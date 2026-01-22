//
//  AddTripIntent.swift
//  Itinero
//
//  Created on 2024
//

import AppIntents
import Foundation

struct AddTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Add New Trip"
    static var description = IntentDescription("Quickly add a new trip to Triply")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip Name")
    var tripName: String
    
    @Parameter(title: "Start Date")
    var startDate: Date
    
    @Parameter(title: "End Date")
    var endDate: Date
    
    func perform() async throws -> some IntentResult {
        // In production, this would create the trip in SwiftData
        return .result()
    }
}

struct ViewUpcomingTripsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Upcoming Trips"
    static var description = IntentDescription("View your upcoming trips in Triply")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}


