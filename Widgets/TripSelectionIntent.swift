//
//  TripSelectionIntent.swift
//  Itinero
//
//  App Intent for selecting which trip to display in the widget
//

import AppIntents
import Foundation

struct TripSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Trip"
    static var description = IntentDescription("Choose which trip to display in the widget")
    
    @Parameter(title: "Trip", description: "The trip to display")
    var trip: TripEntity?
    
    init() {
        self.trip = nil
    }
    
    init(trip: TripEntity?) {
        self.trip = trip
    }
}

// MARK: - Trip Entity

struct TripEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Trip"
    static var defaultQuery = TripQuery()
    
    var id: UUID
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(destination)")
    }
    
    let name: String
    let destination: String
    let startDate: Date
    let endDate: Date
    
    init(id: UUID, name: String, destination: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Trip Query

struct TripQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TripEntity] {
        // Load trips from SwiftData by IDs
        let trips = WidgetDataLoader.loadTrips()
        return trips
            .filter { identifiers.contains($0.id) }
            .map { trip in
                let destination = trip.destinations?.first?.name ?? "No destination"
                return TripEntity(
                    id: trip.id,
                    name: trip.name,
                    destination: destination,
                    startDate: trip.startDate,
                    endDate: trip.endDate
                )
            }
    }
    
    func suggestedEntities() async throws -> [TripEntity] {
        // Return suggested trips (upcoming or active)
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // Prioritize active trips, then upcoming trips
        let activeTrips = trips.filter { $0.startDate <= now && $0.endDate >= now }
        let upcomingTrips = trips.filter { $0.startDate > now }
        
        let suggested = (activeTrips + upcomingTrips).prefix(10)
        
        return suggested.map { trip in
            let destination = trip.destinations?.first?.name ?? "No destination"
            return TripEntity(
                id: trip.id,
                name: trip.name,
                destination: destination,
                startDate: trip.startDate,
                endDate: trip.endDate
            )
        }
    }
    
    func entities(matching string: String) async throws -> [TripEntity] {
        // Search trips by name or destination
        let trips = WidgetDataLoader.loadTrips()
        let searchLower = string.lowercased()
        
        let matching = trips.filter { trip in
            trip.name.lowercased().contains(searchLower) ||
            trip.destinations?.contains { $0.name.lowercased().contains(searchLower) } ?? false
        }
        
        return matching.map { trip in
            let destination = trip.destinations?.first?.name ?? "No destination"
            return TripEntity(
                id: trip.id,
                name: trip.name,
                destination: destination,
                startDate: trip.startDate,
                endDate: trip.endDate
            )
        }
    }
}
