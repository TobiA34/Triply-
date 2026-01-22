//
//  CalendarManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import EventKit
import SwiftUI

@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    
    private let eventStore = EKEventStore()
    
    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            isAuthorized = authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
        } else {
            isAuthorized = authorizationStatus == .authorized
        }
    }
    
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                let status = try await eventStore.requestFullAccessToEvents()
                await MainActor.run {
                    authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    isAuthorized = status
                }
                return status
            } catch {
                print("Calendar access error: \(error)")
                return false
            }
        } else {
            // Fallback for iOS 16
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    Task { @MainActor in
                        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                        self.isAuthorized = granted
                    }
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func addTripToCalendar(_ trip: TripModel) async -> Bool {
        if !isAuthorized {
            let authorized = await requestAccess()
            guard authorized else { return false }
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = trip.name
        event.startDate = trip.startDate
        event.endDate = trip.endDate
        event.notes = trip.notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add location if available
        if let destinations = trip.destinations, !destinations.isEmpty {
            let locationNames = destinations.map { $0.name }.joined(separator: ", ")
            event.location = locationNames
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save event: \(error)")
            return false
        }
    }
    
    func removeTripFromCalendar(_ trip: TripModel) async -> Bool {
        guard isAuthorized else { return false }
        
        let predicate = eventStore.predicateForEvents(withStart: trip.startDate, end: trip.endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        
        if let event = events.first(where: { $0.title == trip.name }) {
            do {
                try eventStore.remove(event, span: .thisEvent)
                return true
            } catch {
                print("Failed to remove event: \(error)")
                return false
            }
        }
        
        return false
    }
    
    func addItineraryToCalendar(_ trip: TripModel) async -> Bool {
        if !isAuthorized {
            let authorized = await requestAccess()
            guard authorized else { return false }
        }
        
        guard let itinerary = trip.itinerary, !itinerary.isEmpty else {
            return false
        }
        
        var successCount = 0
        
        for item in itinerary.sorted(by: { $0.order < $1.order }) {
            let event = EKEvent(eventStore: eventStore)
            event.title = item.title
            event.startDate = item.date
            event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: item.date) ?? item.date
            event.notes = item.details
            event.location = item.location
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            // Set time if available
            if !item.time.isEmpty {
                let timeComponents = item.time.split(separator: ":")
                if timeComponents.count >= 2,
                   let hour = Int(timeComponents[0]),
                   let minute = Int(timeComponents[1]) {
                    var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: item.date)
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    if let newDate = Calendar.current.date(from: dateComponents) {
                        event.startDate = newDate
                        event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: newDate) ?? newDate
                    }
                }
            }
            
            do {
                try eventStore.save(event, span: .thisEvent)
                successCount += 1
            } catch {
                print("Failed to save itinerary item to calendar: \(error)")
            }
        }
        
        return successCount > 0
    }
    
    func addItineraryItemToCalendar(_ item: ItineraryItem, tripName: String) async -> Bool {
        if !isAuthorized {
            let authorized = await requestAccess()
            guard authorized else { return false }
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(tripName): \(item.title)"
        event.startDate = item.date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: item.date) ?? item.date
        event.notes = item.details
        event.location = item.location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Set time if available
        if !item.time.isEmpty {
            let timeComponents = item.time.split(separator: ":")
            if timeComponents.count >= 2,
               let hour = Int(timeComponents[0]),
               let minute = Int(timeComponents[1]) {
                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: item.date)
                dateComponents.hour = hour
                dateComponents.minute = minute
                if let newDate = Calendar.current.date(from: dateComponents) {
                    event.startDate = newDate
                    event.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: newDate) ?? newDate
                }
            }
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save itinerary item to calendar: \(error)")
            return false
        }
    }
}

