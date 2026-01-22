//
//  TripActivityAttributes.swift
//  Itinero
//
//  Live Activity and Dynamic Island attributes for trip tracking
//

import Foundation

// Always define the struct so it's available for compilation
struct TripActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var tripName: String
        var daysUntil: Int
        var isActive: Bool
        var currentDay: Int?
        var totalDays: Int
        var nextActivity: String?
        var status: TripStatus
        var destination: String
        var destinationAddress: String?
        var budget: Double?
        var category: String
        var formattedStartDate: String
        var formattedEndDate: String
        var totalExpenses: Double
        var budgetRemaining: Double?
        
        enum TripStatus: String, Codable {
            case upcoming = "Upcoming"
            case active = "Active"
            case ending = "Ending Soon"
        }
    }
    
    var tripId: UUID
    var destination: String
    var startDate: Date
    var endDate: Date
}

// Make it conform to ActivityAttributes when ActivityKit is available
#if canImport(ActivityKit)
import ActivityKit
extension TripActivityAttributes: ActivityAttributes {}
#endif

