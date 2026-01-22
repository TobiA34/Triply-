//
//  SpotlightIntegration.swift
//  Itinero
//
//  iOS 18+ Spotlight Integration - Make trips searchable
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Trip Entity for Spotlight
@available(iOS 18.0, *)
struct TripEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Trip")
    static var defaultQuery = TripQuery()
    
    var id: UUID
    var displayRepresentation: DisplayRepresentation
    
    init(id: UUID, name: String, destination: String?, startDate: Date) {
        self.id = id
        // DisplayRepresentation requires LocalizedStringResource
        self.displayRepresentation = DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: destination ?? "Trip"),
            image: .init(systemName: "airplane")
        )
    }
}

// MARK: - Trip Query for Spotlight
@available(iOS 18.0, *)
struct TripQuery: EntityQuery {
    func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
        let trips = TripDataAccessor.loadTrips()
        return trips
            .filter { identifiers.contains($0.id) }
            .map { trip in
                TripEntity(
                    id: trip.id,
                    name: trip.name,
                    destination: trip.destinations?.first?.name,
                    startDate: trip.startDate
                )
            }
    }
    
    func entities(matching string: String) async throws -> [TripEntity] {
        let trips = TripDataAccessor.loadTrips()
        let searchTerm = string.lowercased()
        
        return trips
            .filter { trip in
                trip.name.lowercased().contains(searchTerm) ||
                trip.destinations?.contains { $0.name.lowercased().contains(searchTerm) } ?? false ||
                trip.category.lowercased().contains(searchTerm) ||
                trip.notes.lowercased().contains(searchTerm)
            }
            .map { trip in
                TripEntity(
                    id: trip.id,
                    name: trip.name,
                    destination: trip.destinations?.first?.name,
                    startDate: trip.startDate
                )
            }
    }
    
    func suggestedEntities() async throws -> [TripEntity] {
        let trips = TripDataAccessor.loadTrips()
        let now = Date()
        
        // Suggest active and upcoming trips
        let relevantTrips = trips
            .filter { trip in
                (trip.startDate <= now && trip.endDate >= now) || // Active
                trip.startDate > now // Upcoming
            }
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
        
        return relevantTrips.map { trip in
            TripEntity(
                id: trip.id,
                name: trip.name,
                destination: trip.destinations?.first?.name,
                startDate: trip.startDate
            )
        }
    }
}

// MARK: - Open Trip Intent
@available(iOS 18.0, *)
struct OpenTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Trip"
    static var description = IntentDescription("Open a trip in Triply")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip")
    var trip: TripEntity
    
    func perform() async throws -> some IntentResult {
        // Navigate to trip via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTrip"),
            object: nil,
            userInfo: ["tripId": trip.id]
        )
        return .result()
    }
}


//  Itinero
//
//  iOS 18+ Spotlight Integration - Make trips searchable
//

import AppIntents
import Foundation
import SwiftData

// MARK: - Trip Entity for Spotlight
@available(iOS 18.0, *)
struct TripEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Trip")
    static var defaultQuery = TripQuery()
    
    var id: UUID
    var displayRepresentation: DisplayRepresentation
    
    init(id: UUID, name: String, destination: String?, startDate: Date) {
        self.id = id
        // DisplayRepresentation requires LocalizedStringResource
        self.displayRepresentation = DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: destination ?? "Trip"),
            image: .init(systemName: "airplane")
        )
    }
}

// MARK: - Trip Query for Spotlight
@available(iOS 18.0, *)
// MARK: - TripQuery (DUPLICATE - REMOVED)
//     func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
//         let trips = TripDataAccessor.loadTrips()
//         return trips
//             .filter { identifiers.contains($0.id) }
//             .map { trip in
//                 TripEntity(
//                     id: trip.id,
//                     name: trip.name,
//                     destination: trip.destinations?.first?.name,
//                     startDate: trip.startDate
//                 )
//             }
//     }
    
//     func entities(matching string: String) async throws -> [TripEntity] {
//         let trips = TripDataAccessor.loadTrips()
//         let searchTerm = string.lowercased()
        
//         return trips
//             .filter { trip in
//                 trip.name.lowercased().contains(searchTerm) ||
//                 trip.destinations?.contains { $0.name.lowercased().contains(searchTerm) } ?? false ||
//                 trip.category.lowercased().contains(searchTerm) ||
//                 trip.notes.lowercased().contains(searchTerm)
//             }
//             .map { trip in
//                 TripEntity(
//                     id: trip.id,
//                     name: trip.name,
//                     destination: trip.destinations?.first?.name,
//                     startDate: trip.startDate
//                 )
//             }
//     }
    
//     func suggestedEntities() async throws -> [TripEntity] {
//         let trips = TripDataAccessor.loadTrips()
//         let now = Date()
        
        // Suggest active and upcoming trips
//         let relevantTrips = trips
//             .filter { trip in
//                 (trip.startDate <= now && trip.endDate >= now) || // Active
//                 trip.startDate > now // Upcoming
//             }
//             .sorted { $0.startDate < $1.startDate }
//             .prefix(5)
        
//         return relevantTrips.map { trip in
//             TripEntity(
//                 id: trip.id,
//                 name: trip.name,
//                 destination: trip.destinations?.first?.name,
//                 startDate: trip.startDate
//             )
//         }
//     }
// }

// MARK: - Open Trip Intent
@available(iOS 18.0, *)
struct OpenTripIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Trip"
    static var description = IntentDescription("Open a trip in Triply")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip")
    var trip: TripEntity
    
    func perform() async throws -> some IntentResult {
        // Navigate to trip via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToTrip"),
            object: nil,
            userInfo: ["tripId": trip.id]
        )
        return .result()
    }
}


//  Itinero
//
//  iOS 18+ Spotlight Integration - Make trips searchable
//

import AppIntents
import Foundation
import SwiftData
