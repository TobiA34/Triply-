//
//  StructuredDataManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

@MainActor
class StructuredDataManager: ObservableObject {
    static let shared = StructuredDataManager()
    
    private init() {}
    
    func saveItineraryItems(
        _ items: [StructuredItineraryItem],
        to trip: TripModel,
        in context: ModelContext
    ) async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime]
        
        for item in items {
            var itemDate = trip.startDate
            if let dateString = item.date,
               let parsedDate = dateFormatter.date(from: dateString) {
                itemDate = parsedDate
            } else {
                // Calculate date based on day
                if let date = Calendar.current.date(byAdding: .day, value: item.day - 1, to: trip.startDate) {
                    itemDate = date
                }
            }
            
            let itineraryItem = ItineraryItem(
                day: item.day,
                date: itemDate,
                title: item.title,
                details: item.details ?? "",
                time: item.time ?? "",
                location: item.location ?? "",
                order: item.order ?? 0,
                isBooked: item.isBooked ?? false,
                bookingReference: item.bookingReference ?? ""
            )
            
            context.insert(itineraryItem)
            
            if trip.itinerary == nil {
                trip.itinerary = []
            }
            trip.itinerary?.append(itineraryItem)
        }
        
        try context.save()
    }
    
    func saveSuggestion(
        _ suggestion: StructuredSuggestion,
        to trip: TripModel,
        in context: ModelContext
    ) async throws {
        // Handle suggestion actions
        switch suggestion.action {
        case "add_destination":
            let location = suggestion.metadata?["location"] ?? suggestion.title.replacingOccurrences(of: "Add ", with: "")
            if !location.isEmpty {
                let destination = DestinationModel(
                    name: location,
                    address: "",
                    notes: suggestion.description,
                    order: trip.destinations?.count ?? 0
                )
                context.insert(destination)
                
                if trip.destinations == nil {
                    trip.destinations = []
                }
                trip.destinations?.append(destination)
            }
        case "create_itinerary":
            // This would trigger itinerary creation
            break
        case "set_budget":
            // This would open budget setting
            break
        default:
            break
        }
        
        try context.save()
    }
    
    func saveDocument(
        _ document: StructuredDocument,
        to trip: TripModel,
        relatedItem: ItineraryItem? = nil,
        relatedExpense: Expense? = nil,
        in context: ModelContext
    ) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime]
        
        var docDate: Date? = nil
        if let dateString = document.date,
           let parsedDate = dateFormatter.date(from: dateString) {
            docDate = parsedDate
        }
        
        let tripDocument = TripDocument(
            type: document.type,
            title: document.title,
            notes: document.description ?? "",
            fileName: document.fileName,
            date: docDate,
            amount: document.amount,
            trip: trip,
            relatedItineraryItem: relatedItem,
            relatedExpense: relatedExpense
        )
        
        context.insert(tripDocument)
        try context.save()
    }
}

