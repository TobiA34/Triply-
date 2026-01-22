//
//  TripSharingManager.swift
//  Itinero
//
//  Trip sharing functionality - Roamy-style link sharing
//

import Foundation
import SwiftData

struct SharedTripData: Codable {
    let tripId: UUID
    let name: String
    let startDate: Date
    let endDate: Date
    let category: String
    let notes: String
    let budget: Double?
    let destinations: [SharedDestinationData]
    let itinerary: [SharedItineraryData]?
    
    struct SharedDestinationData: Codable {
        let name: String
        let address: String
        let notes: String
        let latitude: Double?
        let longitude: Double?
        let sourceURL: String?
        let reviewURL: String?
    }
    
    struct SharedItineraryData: Codable {
        let day: Int
        let title: String
        let details: String
        let time: String
        let location: String
    }
}

@MainActor
class TripSharingManager: ObservableObject {
    static let shared = TripSharingManager()
    
    private init() {}
    
    /// Generates a shareable link for a trip
    /// In production, this would upload to a server and return a URL
    /// For now, we'll encode the trip data as a base64 string
    func generateShareLink(for trip: TripModel) -> String {
        let sharedData = createSharedTripData(from: trip)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(sharedData)
            let base64String = jsonData.base64EncodedString()
            
            // In production, this would be: "https://itinero.app/share/\(base64String)"
            // For now, return a data URI that can be shared
            return "itinero://share/\(base64String)"
        } catch {
            print("Failed to encode trip data: \(error)")
            return ""
        }
    }
    
    /// Imports a trip from a shared link
    func importTrip(from link: String, into context: ModelContext) throws -> TripModel? {
        // Extract base64 string from link
        guard let base64String = link.components(separatedBy: "/").last else {
            return nil
        }
        
        guard let jsonData = Data(base64Encoded: base64String) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let sharedData = try decoder.decode(SharedTripData.self, from: jsonData)
            
            return createTrip(from: sharedData, in: context)
        } catch {
            print("Failed to decode trip data: \(error)")
            throw error
        }
    }
    
    /// Creates shareable text representation
    func createShareText(for trip: TripModel) -> String {
        var text = "🗺️ \(trip.name)\n"
        text += "📅 \(trip.formattedDateRange)\n"
        text += "⏱️ \(trip.duration) days\n\n"
        
        if let destinations = trip.destinations, !destinations.isEmpty {
            text += "📍 Destinations:\n"
            for dest in destinations.sorted(by: { $0.order < $1.order }) {
                text += "• \(dest.name)\n"
                if !dest.address.isEmpty {
                    text += "  \(dest.address)\n"
                }
            }
            text += "\n"
        }
        
        if let itinerary = trip.itinerary, !itinerary.isEmpty {
            text += "📋 Itinerary:\n"
            let groupedByDay = Dictionary(grouping: itinerary, by: { $0.day })
            for day in groupedByDay.keys.sorted() {
                text += "\nDay \(day):\n"
                for item in groupedByDay[day]?.sorted(by: { $0.order < $1.order }) ?? [] {
                    text += "• \(item.time) - \(item.title)\n"
                }
            }
        }
        
        if !trip.notes.isEmpty {
            text += "\n📝 Notes: \(trip.notes)\n"
        }
        
        text += "\n✨ Shared from Itinero"
        
        return text
    }
    
    // MARK: - Private Helpers
    
    private func createSharedTripData(from trip: TripModel) -> SharedTripData {
        let destinations = (trip.destinations ?? []).map { dest in
            SharedTripData.SharedDestinationData(
                name: dest.name,
                address: dest.address,
                notes: dest.notes,
                latitude: dest.latitude,
                longitude: dest.longitude,
                sourceURL: dest.sourceURL,
                reviewURL: dest.reviewURL
            )
        }
        
        let itinerary = (trip.itinerary ?? []).map { item in
            SharedTripData.SharedItineraryData(
                day: item.day,
                title: item.title,
                details: item.details,
                time: item.time,
                location: item.location
            )
        }
        
        return SharedTripData(
            tripId: trip.id,
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            category: trip.category,
            notes: trip.notes,
            budget: trip.budget,
            destinations: destinations,
            itinerary: itinerary.isEmpty ? nil : itinerary
        )
    }
    
    private func createTrip(from sharedData: SharedTripData, in context: ModelContext) -> TripModel {
        let trip = TripModel(
            name: "\(sharedData.name) (Shared)",
            startDate: sharedData.startDate,
            endDate: sharedData.endDate,
            notes: sharedData.notes,
            category: sharedData.category,
            budget: sharedData.budget
        )
        
        // Add destinations
        for (index, destData) in sharedData.destinations.enumerated() {
            let destination = DestinationModel(
                name: destData.name,
                address: destData.address,
                notes: destData.notes,
                order: index,
                latitude: destData.latitude,
                longitude: destData.longitude,
                sourceURL: destData.sourceURL,
                reviewURL: destData.reviewURL,
                savedFromSocial: destData.sourceURL != nil
            )
            context.insert(destination)
            trip.destinations?.append(destination)
        }
        
        // Add itinerary if available
        if let itineraryData = sharedData.itinerary {
            for itemData in itineraryData {
                guard let itemDate = Calendar.current.date(byAdding: .day, value: itemData.day - 1, to: trip.startDate) else {
                    continue
                }
                
                let item = ItineraryItem(
                    day: itemData.day,
                    date: itemDate,
                    title: itemData.title,
                    details: itemData.details,
                    time: itemData.time,
                    location: itemData.location,
                    order: trip.itinerary?.count ?? 0
                )
                context.insert(item)
                trip.itinerary?.append(item)
            }
        }
        
        context.insert(trip)
        return trip
    }
}




