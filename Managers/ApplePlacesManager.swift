//
//  ApplePlacesManager.swift
//  Itinero
//
//  Apple MapKit-based place search using MKLocalSearch
//

import Foundation
import MapKit
import CoreLocation
import SwiftUI

// MARK: - Apple Place Model
struct ApplePlace: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let location: CLLocationCoordinate2D
    let category: String
    let phoneNumber: String?
    let url: URL?
    let distance: Double? // Distance in meters
    
    // MapKit placemark
    let placemark: MKPlacemark
    
    init(from mapItem: MKMapItem, userLocation: CLLocation? = nil) {
        self.name = mapItem.name ?? "Unknown Place"
        self.address = ApplePlace.formatAddress(mapItem.placemark)
        self.location = mapItem.placemark.coordinate
        self.placemark = mapItem.placemark
        self.phoneNumber = mapItem.phoneNumber
        self.url = mapItem.url
        
        // Calculate distance if user location available
        if let userLocation = userLocation {
            let placeLocation = CLLocation(
                latitude: mapItem.placemark.coordinate.latitude,
                longitude: mapItem.placemark.coordinate.longitude
            )
            self.distance = userLocation.distance(from: placeLocation)
        } else {
            self.distance = nil
        }
        
        // Determine category from point of interest
        self.category = ApplePlace.determineCategory(from: mapItem)
    }
    
    private static func formatAddress(_ placemark: MKPlacemark) -> String {
        var addressComponents: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            addressComponents.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            addressComponents.append(street)
        }
        if let city = placemark.locality {
            addressComponents.append(city)
        }
        if let state = placemark.administrativeArea {
            addressComponents.append(state)
        }
        if let zip = placemark.postalCode {
            addressComponents.append(zip)
        }
        
        return addressComponents.isEmpty ? "Address not available" : addressComponents.joined(separator: " ")
    }
    
    private static func determineCategory(from mapItem: MKMapItem) -> String {
        // Check point of interest category
        if let pointOfInterestCategory = mapItem.pointOfInterestCategory {
            switch pointOfInterestCategory {
            case .restaurant, .bakery, .brewery, .cafe, .foodMarket, .winery:
                return "Restaurant"
            case .museum, .library:
                return "Museum"
            case .park, .beach, .nationalPark:
                return "Park"
            case .store:
                return "Shopping"
            case .nightlife:
                return "Nightlife"
            case .hotel:
                return "Accommodation"
            case .theater, .movieTheater, .stadium, .amusementPark:
                return "Entertainment"
            case .fitnessCenter:
                return "Fitness"
            default:
                return "Activity"
            }
        }
        
        // Fallback to checking name/address for keywords
        let name = (mapItem.name ?? "").lowercased()
        if name.contains("restaurant") || name.contains("cafe") || name.contains("diner") {
            return "Restaurant"
        } else if name.contains("museum") || name.contains("gallery") {
            return "Museum"
        } else if name.contains("park") {
            return "Park"
        } else if name.contains("mall") || name.contains("shop") {
            return "Shopping"
        } else {
            return "Activity"
        }
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "" }
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}

// MARK: - Apple Places Manager
@MainActor
class ApplePlacesManager: ObservableObject {
    static let shared = ApplePlacesManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // Initialization complete
    }
    
    // MARK: - Search Nearby Places
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Double = 5000, // meters
        category: MKPointOfInterestCategory? = nil,
        searchText: String? = nil
    ) async -> [ApplePlace] {
        isLoading = true
        defer { isLoading = false }
        
        // Validate location coordinates
        guard abs(location.latitude) <= 90 && abs(location.longitude) <= 180 else {
            errorMessage = "Invalid location coordinates"
            return []
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText ?? "restaurants, attractions, museums, parks"
        
        // Ensure valid coordinate span (clamp between 0.001 and 0.5 degrees)
        let latitudeDelta = max(0.001, min(radius / 111000, 0.5))
        let longitudeDelta = max(0.001, min(radius / 111000, 0.5))
        
        request.region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
        
        // Filter by point of interest category if provided
        if let category = category {
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])
        } else {
            // Include common categories
            request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
                .restaurant,
                .cafe,
                .museum,
                .park,
                .beach,
                .nightlife,
                .theater,
                .amusementPark,
                .stadium
            ])
        }
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            // Get user location for distance calculation
            let userLocation = EnhancedLocationManager.shared.currentLocation
            
            // Safely map items, filtering out any invalid ones
            let places = response.mapItems.compactMap { mapItem -> ApplePlace? in
                // Validate map item has required data
                let coord = mapItem.placemark.coordinate
                guard abs(coord.latitude) <= 90 && abs(coord.longitude) <= 180 else {
                    return nil
                }
                return ApplePlace(from: mapItem, userLocation: userLocation)
            }
            
            // Sort by distance if available
            let sortedPlaces = places.sorted { place1, place2 in
                if let dist1 = place1.distance, let dist2 = place2.distance {
                    return dist1 < dist2
                }
                return place1.distance != nil
            }
            
            errorMessage = nil
            return Array(sortedPlaces.prefix(20)) // Return top 20
        } catch {
            // Handle common MapKit errors more gracefully so the user
            // doesn't see obscure MKErrorDomain codes.
            if let mkError = error as? MKError {
                switch mkError.code {
                case .placemarkNotFound, .directionsNotFound:
                    // Treat as “no results” rather than a hard error
                    errorMessage = "No places found here. Try a different area or search term."
                    print("ℹ️ ApplePlacesManager: no places found for query '\(searchText ?? "")' (\(mkError))")
                    return []
                case . serverFailure:
                    errorMessage = "Unable to reach Apple Maps. Please check your internet connection and try again."
                case .loadingThrottled:
                    errorMessage = "Apple Maps is temporarily busy. Please wait a moment and try again."
                default:
                    errorMessage = "Unable to search places right now. Please try again in a moment."
                }
            } else {
                errorMessage = "Unable to search places right now. Please try again."
            }
            
            print("❌ ApplePlacesManager error: \(error)")
            return []
        }
    }
    
    // MARK: - Search by Category
    func searchByCategory(
        location: CLLocationCoordinate2D,
        category: MKPointOfInterestCategory,
        radius: Double = 5000
    ) async -> [ApplePlace] {
        return await searchNearby(
            location: location,
            radius: radius,
            category: category
        )
    }
    
    // MARK: - Suggest Activities for Trip
    func suggestActivities(
        for trip: TripModel,
        using location: CLLocationCoordinate2D? = nil
    ) async -> [ApplePlace] {
        // Use provided location, trip destination, or device location
        let searchLocation: CLLocationCoordinate2D
        
        if let location = location {
            // Validate provided location
            guard abs(location.latitude) <= 90 && abs(location.longitude) <= 180 else {
                errorMessage = "Invalid location coordinates"
                return []
            }
            searchLocation = location
        } else if let firstDestination = trip.destinations?.first,
                  let lat = firstDestination.latitude,
                  let lon = firstDestination.longitude,
                  abs(lat) <= 90,
                  abs(lon) <= 180 {
            searchLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else if let deviceLocation = EnhancedLocationManager.shared.currentLocation {
            searchLocation = deviceLocation.coordinate
        } else {
            // Request location if not available
            // First check and request authorization if needed
            if EnhancedLocationManager.shared.authorizationStatus == .notDetermined {
                EnhancedLocationManager.shared.requestAuthorization()
                // Wait a moment for authorization
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
            
            // Only start updates if authorized
            if EnhancedLocationManager.shared.authorizationStatus == .authorizedWhenInUse ||
               EnhancedLocationManager.shared.authorizationStatus == .authorizedAlways {
                EnhancedLocationManager.shared.startLocationUpdates()
                // Wait a bit for location
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            }
            
            if let deviceLocation = EnhancedLocationManager.shared.currentLocation {
                searchLocation = deviceLocation.coordinate
            } else {
                // Try async location request
                do {
                    let location = try await EnhancedLocationManager.shared.requestLocation()
                    searchLocation = location.coordinate
                } catch {
                    errorMessage = "Unable to determine location. Please enable location services."
                    return []
                }
            }
        }
        
        // Search for popular activities
        var allPlaces: [ApplePlace] = []
        
        // Search different categories
        let categories: [MKPointOfInterestCategory] = [
            .restaurant,
            .cafe,
            .museum,
            .park,
            .beach,
            .store,
            .nightlife,
            .theater,
            .amusementPark
        ]
        
        // Search all categories with error handling
        for category in categories {
            let places = await searchByCategory(
                location: searchLocation,
                category: category,
                radius: 5000
            )
            allPlaces.append(contentsOf: places)
        }
        
        // Remove duplicates (by name and location proximity)
        var uniquePlaces: [ApplePlace] = []
        var seenNames: Set<String> = []
        
        for place in allPlaces {
            let key = "\(place.name)-\(Int(place.location.latitude * 1000))-\(Int(place.location.longitude * 1000))"
            if !seenNames.contains(key) {
                seenNames.insert(key)
                uniquePlaces.append(place)
            }
        }
        
        // Sort by distance
        let sortedPlaces = uniquePlaces.sorted { place1, place2 in
            if let dist1 = place1.distance, let dist2 = place2.distance {
                return dist1 < dist2
            }
            return place1.distance != nil
        }
        
        return Array(sortedPlaces.prefix(20)) // Return top 20
    }
    
    // MARK: - Search with Text Query
    func searchWithQuery(
        query: String,
        location: CLLocationCoordinate2D? = nil,
        radius: Double = 5000
    ) async -> [ApplePlace] {
        // Validate query
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Search query cannot be empty"
            return []
        }
        
        let searchLocation: CLLocationCoordinate2D
        
        if let location = location {
            // Validate provided location
            guard abs(location.latitude) <= 90 && abs(location.longitude) <= 180 else {
                errorMessage = "Invalid location coordinates"
                return []
            }
            searchLocation = location
        } else if let deviceLocation = EnhancedLocationManager.shared.currentLocation {
            searchLocation = deviceLocation.coordinate
        } else {
            errorMessage = "Location required for search"
            return []
        }
        
        return await searchNearby(
            location: searchLocation,
            radius: radius,
            searchText: query
        )
    }
}

