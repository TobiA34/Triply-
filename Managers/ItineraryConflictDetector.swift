//
//  ItineraryConflictDetector.swift
//  Itinero
//
//  Detects time conflicts and overlapping activities
//

import Foundation
import SwiftData

struct TimeConflict {
    let activity1: ItineraryItem
    let activity2: ItineraryItem
    let conflictType: ConflictType
    let message: String
    
    enum ConflictType {
        case overlapping
        case tooClose
        case travelTimeConflict
    }
}

@MainActor
class ItineraryConflictDetector {
    static let shared = ItineraryConflictDetector()
    
    private init() {}
    
    /// Detects conflicts in a day's activities
    func detectConflicts(for activities: [ItineraryItem]) -> [TimeConflict] {
        var conflicts: [TimeConflict] = []
        let sortedActivities = activities.sorted { $0.order < $1.order }
        
        for i in 0..<sortedActivities.count {
            let activity1 = sortedActivities[i]
            
            // Check against all subsequent activities
            for j in (i+1)..<sortedActivities.count {
                let activity2 = sortedActivities[j]
                
                // Check for overlapping times
                if let overlap = checkTimeOverlap(activity1: activity1, activity2: activity2) {
                    conflicts.append(overlap)
                }
                
                // Check if activities are too close together (less than 15 min buffer)
                if let tooClose = checkTooClose(activity1: activity1, activity2: activity2) {
                    conflicts.append(tooClose)
                }
            }
        }
        
        return conflicts
    }
    
    /// Checks if two activities have overlapping times
    private func checkTimeOverlap(activity1: ItineraryItem, activity2: ItineraryItem) -> TimeConflict? {
        guard let time1 = parseTime(activity1.time),
              let time2 = parseTime(activity2.time),
              Calendar.current.isDate(activity1.date, inSameDayAs: activity2.date) else {
            return nil
        }
        
        // Default to 60 minutes since estimatedDuration is not available on ItineraryItem
        let duration1 = 60 // Default 1 hour
        let duration2 = 60
        
        let end1 = time1.addingTimeInterval(TimeInterval(duration1 * 60))
        let end2 = time2.addingTimeInterval(TimeInterval(duration2 * 60))
        
        // Check if times overlap
        if (time1 < end2 && time2 < end1) {
            return TimeConflict(
                activity1: activity1,
                activity2: activity2,
                conflictType: .overlapping,
                message: "\(activity1.title) and \(activity2.title) overlap in time"
            )
        }
        
        return nil
    }
    
    /// Checks if activities are too close together (less than 15 min buffer)
    private func checkTooClose(activity1: ItineraryItem, activity2: ItineraryItem) -> TimeConflict? {
        guard let time1 = parseTime(activity1.time),
              let time2 = parseTime(activity2.time),
              Calendar.current.isDate(activity1.date, inSameDayAs: activity2.date) else {
            return nil
        }
        
        // Default to 60 minutes since estimatedDuration is not available on ItineraryItem
        let duration1 = 60
        let end1 = time1.addingTimeInterval(TimeInterval(duration1 * 60))
        
        // Check if activity2 starts less than 15 minutes after activity1 ends
        let timeDifference = time2.timeIntervalSince(end1)
        if timeDifference < 0 {
            // Already handled by overlap check
            return nil
        }
        
        if timeDifference < 15 * 60 { // Less than 15 minutes
            return TimeConflict(
                activity1: activity1,
                activity2: activity2,
                conflictType: .tooClose,
                message: "\(activity1.title) and \(activity2.title) are too close together (only \(Int(timeDifference / 60)) min apart)"
            )
        }
        
        return nil
    }
    
    /// Parses time string to Date
    private func parseTime(_ timeString: String) -> Date? {
        guard !timeString.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // "2:30 PM"
        
        // Try different formats
        if let date = formatter.date(from: timeString) {
            return date
        }
        
        formatter.dateFormat = "HH:mm" // "14:30"
        if let date = formatter.date(from: timeString) {
            return date
        }
        
        return nil
    }
    
    /// Calculates travel time between two activities
    func calculateTravelTime(from activity1: ItineraryItem, to activity2: ItineraryItem) -> Int? {
        // This would use MapKit or a routing service in production
        // For now, return a simple estimate based on distance
        // In production, use MKDirections or similar
        
        // Placeholder: return estimated travel time
        // Real implementation would geocode locations and calculate route
        return nil
    }
}



