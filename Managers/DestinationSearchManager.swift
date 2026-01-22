//
//  DestinationSearchManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import CoreLocation

struct SearchResult: Identifiable {
    let id: String
    let name: String
    let address: String
    let country: String
    let coordinates: CLLocationCoordinate2D?
}

@MainActor
class DestinationSearchManager: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    // Popular destinations database
    let popularDestinations: [SearchResult] = [
        SearchResult(id: "paris", name: "Paris", address: "Paris, France", country: "France", coordinates: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)),
        SearchResult(id: "london", name: "London", address: "London, UK", country: "United Kingdom", coordinates: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)),
        SearchResult(id: "tokyo", name: "Tokyo", address: "Tokyo, Japan", country: "Japan", coordinates: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)),
        SearchResult(id: "newyork", name: "New York", address: "New York, USA", country: "United States", coordinates: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)),
        SearchResult(id: "rome", name: "Rome", address: "Rome, Italy", country: "Italy", coordinates: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964)),
        SearchResult(id: "barcelona", name: "Barcelona", address: "Barcelona, Spain", country: "Spain", coordinates: CLLocationCoordinate2D(latitude: 41.3851, longitude: 2.1734)),
        SearchResult(id: "dubai", name: "Dubai", address: "Dubai, UAE", country: "United Arab Emirates", coordinates: CLLocationCoordinate2D(latitude: 25.2048, longitude: 55.2708)),
        SearchResult(id: "sydney", name: "Sydney", address: "Sydney, Australia", country: "Australia", coordinates: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)),
        SearchResult(id: "singapore", name: "Singapore", address: "Singapore", country: "Singapore", coordinates: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198)),
        SearchResult(id: "bangkok", name: "Bangkok", address: "Bangkok, Thailand", country: "Thailand", coordinates: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018))
    ]
    
    func searchDestinations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Simulate API search with local data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let lowerQuery = query.lowercased()
            self.searchResults = self.popularDestinations.filter { destination in
                destination.name.lowercased().contains(lowerQuery) ||
                destination.address.lowercased().contains(lowerQuery) ||
                destination.country.lowercased().contains(lowerQuery)
            }
            self.isSearching = false
        }
    }
    
    func clearSearch() {
        searchResults = []
    }
}

