//
//  TripManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftUI

class TripManager: ObservableObject {
    @Published var trips: [Trip] = []
    
    init() {
        loadSampleData()
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
        }
    }
    
    func addDestination(_ destination: Destination, to trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].destinations.append(destination)
        }
    }
    
    func deleteDestination(_ destination: Destination, from trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].destinations.removeAll { $0.id == destination.id }
        }
    }
    
    private func loadSampleData() {
        // Sample data for MVP demonstration
        let sampleTrip = Trip(
            name: "Summer Europe Adventure",
            startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
            destinations: [
                Destination(name: "Paris", address: "Paris, France", notes: "Visit Eiffel Tower"),
                Destination(name: "Rome", address: "Rome, Italy", notes: "Colosseum tour"),
                Destination(name: "Barcelona", address: "Barcelona, Spain", notes: "Sagrada Familia")
            ],
            notes: "First time in Europe!"
        )
        trips.append(sampleTrip)
    }
}



