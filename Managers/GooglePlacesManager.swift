//
//  GooglePlacesManager.swift
//  Itinero
//
//  Google Places API integration for activity suggestions
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Google Place Model
struct GooglePlace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let types: [String]
    let location: CLLocationCoordinate2D
    let photoReference: String?
    let priceLevel: Int?
    let openingHours: OpeningHours?
    
    struct OpeningHours: Codable, Equatable {
        let openNow: Bool?
    }
    
    // Custom Equatable implementation since CLLocationCoordinate2D is not Equatable
    static func == (lhs: GooglePlace, rhs: GooglePlace) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.location.latitude == rhs.location.latitude &&
               lhs.location.longitude == rhs.location.longitude
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "place_id"
        case name
        case address = "formatted_address"
        case rating
        case userRatingsTotal = "user_ratings_total"
        case types
        case geometry
        case photos
        case priceLevel = "price_level"
        case openingHours = "opening_hours"
    }
    
    enum GeometryKeys: String, CodingKey {
        case location
    }
    
    enum LocationKeys: String, CodingKey {
        case lat
        case lng
    }
    
    enum PhotoKeys: String, CodingKey {
        case photoReference = "photo_reference"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        userRatingsTotal = try container.decodeIfPresent(Int.self, forKey: .userRatingsTotal)
        types = try container.decodeIfPresent([String].self, forKey: .types) ?? []
        priceLevel = try container.decodeIfPresent(Int.self, forKey: .priceLevel)
        openingHours = try container.decodeIfPresent(OpeningHours.self, forKey: .openingHours)
        
        // Decode geometry
        let geometryContainer = try container.nestedContainer(keyedBy: GeometryKeys.self, forKey: .geometry)
        let locationContainer = try geometryContainer.nestedContainer(keyedBy: LocationKeys.self, forKey: .location)
        let lat = try locationContainer.decode(Double.self, forKey: .lat)
        let lng = try locationContainer.decode(Double.self, forKey: .lng)
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        // Decode photo reference (first photo)
        if let photos = try? container.decodeIfPresent([PhotoData].self, forKey: .photos),
           let firstPhoto = photos.first {
            photoReference = firstPhoto.photoReference
        } else {
            photoReference = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        // Not needed for our use case
    }
    
    private struct PhotoData: Codable {
        let photoReference: String
        
        enum CodingKeys: String, CodingKey {
            case photoReference = "photo_reference"
        }
    }
    
    // Computed properties
    var category: String {
        // Map Google types to our categories
        if types.contains("restaurant") || types.contains("cafe") || types.contains("food") {
            return "Restaurant"
        } else if types.contains("museum") || types.contains("art_gallery") {
            return "Museum"
        } else if types.contains("park") || types.contains("tourist_attraction") {
            return "Attraction"
        } else if types.contains("shopping_mall") || types.contains("store") {
            return "Shopping"
        } else if types.contains("bar") || types.contains("night_club") {
            return "Nightlife"
        } else if types.contains("lodging") || types.contains("hotel") {
            return "Accommodation"
        } else {
            return "Activity"
        }
    }
    
    var formattedRating: String {
        guard let rating = rating else { return "No rating" }
        return String(format: "%.1f", rating)
    }
    
    var isOpenNow: Bool {
        openingHours?.openNow ?? false
    }
}

// MARK: - Google Places Response
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
    let errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case results
        case status
        case errorMessage = "error_message"
    }
}

// MARK: - Google Places Manager
@MainActor
class GooglePlacesManager: ObservableObject {
    static let shared = GooglePlacesManager()
    
    // Get API key from Info.plist or environment
    private var apiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String, !key.isEmpty {
            return key
        }
        // Fallback to environment variable or default
        return ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"] ?? ""
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Search Nearby Places
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        type: String? = nil,
        keyword: String? = nil
    ) async -> [GooglePlace] {
        guard !apiKey.isEmpty else {
            errorMessage = "Google Places API key not configured. Add 'GooglePlacesAPIKey' to Info.plist"
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log the response for debugging
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Google Places API Response Status: \(httpResponse.statusCode)")
            }
            
            // Try to decode response
            let placesResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
            
            print("📡 Google Places API Status: \(placesResponse.status)")
            
            if placesResponse.status == "OK" {
                errorMessage = nil
                print("✅ Successfully fetched \(placesResponse.results.count) places")
                return placesResponse.results
            } else if placesResponse.status == "ZERO_RESULTS" {
                errorMessage = nil // Not an error, just no results
                print("ℹ️ No results found for this location")
                return []
            } else {
                let errorMsg = placesResponse.errorMessage ?? "Places API error: \(placesResponse.status)"
                errorMessage = errorMsg
                print("❌ Google Places API Error: \(errorMsg)")
                
                // Provide helpful error messages
                if placesResponse.status == "REQUEST_DENIED" {
                    errorMessage = "API key invalid or not configured. Add 'GooglePlacesAPIKey' to Info.plist"
                } else if placesResponse.status == "OVER_QUERY_LIMIT" {
                    errorMessage = "API quota exceeded. Check your Google Cloud billing."
                } else if placesResponse.status == "INVALID_REQUEST" {
                    errorMessage = "Invalid request. Check location coordinates."
                }
                
                return []
            }
        } catch {
            let errorMsg = "Failed to fetch places: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ GooglePlacesManager error: \(error)")
            print("❌ Error details: \(error)")
            return []
        }
    }
    
    // MARK: - Get Place Details
    func getPlaceDetails(placeId: String) async -> GooglePlace? {
        guard !apiKey.isEmpty else {
            errorMessage = "Google Places API key not configured"
            return nil
        }
        
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        urlComponents.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,formatted_address,rating,user_ratings_total,types,geometry,photos,price_level,opening_hours"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let result = json?["result"] as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: result)
                let place = try JSONDecoder().decode(GooglePlace.self, from: jsonData)
                return place
            }
            
            return nil
        } catch {
            errorMessage = "Failed to fetch place details: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Get Photo URL
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        guard !apiKey.isEmpty else { return nil }
        
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")!
        urlComponents.queryItems = [
            URLQueryItem(name: "maxwidth", value: "\(maxWidth)"),
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        return urlComponents.url
    }
    
    // MARK: - Suggest Activities for Trip
    func suggestActivities(
        for trip: TripModel,
        using location: CLLocationCoordinate2D? = nil
    ) async -> [GooglePlace] {
        // Use provided location, trip destination, or device location
        let searchLocation: CLLocationCoordinate2D
        
        if let location = location {
            searchLocation = location
        } else if let firstDestination = trip.destinations?.first,
                  let lat = firstDestination.latitude,
                  let lon = firstDestination.longitude {
            searchLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else if let deviceLocation = EnhancedLocationManager.shared.currentLocation {
            searchLocation = deviceLocation.coordinate
        } else {
            // Request location if not available
            EnhancedLocationManager.shared.startLocationUpdates()
            // Wait a bit for location
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
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
        var allPlaces: [GooglePlace] = []
        
        // Search different categories
        let categories = [
            ("tourist_attraction", "Attractions"),
            ("restaurant", "Restaurants"),
            ("museum", "Museums"),
            ("park", "Parks"),
            ("shopping_mall", "Shopping")
        ]
        
        for (type, _) in categories {
            let places = await searchNearby(location: searchLocation, radius: 5000, type: type)
            allPlaces.append(contentsOf: places)
        }
        
        // Remove duplicates and sort by rating
        let uniquePlaces = Array(Set(allPlaces.map { $0.id }))
            .compactMap { id in allPlaces.first { $0.id == id } }
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        
        return Array(uniquePlaces.prefix(20)) // Return top 20
    }
}

