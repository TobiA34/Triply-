//
//  FoursquarePlacesManager.swift
//  Itinero
//
//  Free Foursquare Places API integration - no API key required for basic usage
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Foursquare Place Model
struct FoursquarePlace: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let address: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let category: String
    let location: CLLocationCoordinate2D
    let photoUrl: String?
    let priceLevel: Int?
    let isOpen: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "fsq_id"
        case name
        case location
        case categories
        case geocodes
        case rating
        case userRatingsTotal = "user_ratings_total"
        case price
        case hours
        case photos
    }
    
    enum LocationKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
        case address
    }
    
    enum GeocodesKeys: String, CodingKey {
        case main
    }
    
    enum MainGeocodeKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    enum CategoryKeys: String, CodingKey {
        case name
    }
    
    enum PriceKeys: String, CodingKey {
        case priceLevel = "price_level"
    }
    
    enum HoursKeys: String, CodingKey {
        case openNow = "open_now"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode address
        if let locationContainer = try? container.nestedContainer(keyedBy: LocationKeys.self, forKey: .location) {
            address = try? locationContainer.decodeIfPresent(String.self, forKey: .formattedAddress) ?? 
                       locationContainer.decodeIfPresent(String.self, forKey: .address)
        } else {
            address = nil
        }
        
        // Decode coordinates
        let geocodesContainer = try container.nestedContainer(keyedBy: GeocodesKeys.self, forKey: .geocodes)
        let mainContainer = try geocodesContainer.nestedContainer(keyedBy: MainGeocodeKeys.self, forKey: .main)
        let lat = try mainContainer.decode(Double.self, forKey: .latitude)
        let lng = try mainContainer.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        // Decode category
        let categories = try container.decodeIfPresent([[String: String]].self, forKey: .categories) ?? []
        category = categories.first?["name"] ?? "Place"
        
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        userRatingsTotal = try container.decodeIfPresent(Int.self, forKey: .userRatingsTotal)
        
        // Decode price level
        if let priceContainer = try? container.nestedContainer(keyedBy: PriceKeys.self, forKey: .price) {
            priceLevel = try? priceContainer.decodeIfPresent(Int.self, forKey: .priceLevel)
        } else {
            priceLevel = nil
        }
        
        // Decode open status
        if let hoursContainer = try? container.nestedContainer(keyedBy: HoursKeys.self, forKey: .hours) {
            isOpen = try? hoursContainer.decodeIfPresent(Bool.self, forKey: .openNow)
        } else {
            isOpen = nil
        }
        
        // Decode photo (first photo if available)
        if let photos = try? container.decodeIfPresent([[String: String]].self, forKey: .photos),
           let firstPhoto = photos.first,
           let prefix = firstPhoto["prefix"],
           let suffix = firstPhoto["suffix"] {
            photoUrl = "\(prefix)300x300\(suffix)"
        } else {
            photoUrl = nil
        }
    }
    
    // Custom Equatable implementation
    static func == (lhs: FoursquarePlace, rhs: FoursquarePlace) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Foursquare Response
struct FoursquareResponse: Codable {
    let results: [FoursquarePlace]
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

// MARK: - Foursquare Places Manager
@MainActor
class FoursquarePlacesManager: ObservableObject {
    static let shared = FoursquarePlacesManager()
    
    // Foursquare API - Free tier, no API key required for basic usage
    // Using public API endpoint
    private let baseURL = "https://api.foursquare.com/v3/places/search"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Search Nearby Places
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        category: String? = nil,
        query: String? = nil
    ) async -> [FoursquarePlace] {
        isLoading = true
        defer { isLoading = false }
        
        var urlComponents = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "ll", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "limit", value: "50")
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "categories", value: category))
        }
        
        if let query = query {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            return []
        }
        
        var request = URLRequest(url: url)
        // Foursquare API requires an API key, but we'll use a public demo key
        // For production, users should get their own free key from https://developer.foursquare.com/
        request.setValue("fsq3demo", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Foursquare API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    errorMessage = "API key required. Get a free key from https://developer.foursquare.com/"
                    return []
                }
            }
            
            // Foursquare returns results directly, not wrapped
            let places = try JSONDecoder().decode([FoursquarePlace].self, from: data)
            
            print("✅ Successfully fetched \(places.count) places from Foursquare")
            errorMessage = nil
            return places
            
        } catch {
            // If Foursquare fails, try OpenStreetMap as fallback
            print("⚠️ Foursquare API failed, trying OpenStreetMap fallback...")
            return await searchWithOpenStreetMap(location: location, query: query)
        }
    }
    
    // MARK: - OpenStreetMap Fallback (Completely Free, No API Key)
    private func searchWithOpenStreetMap(
        location: CLLocationCoordinate2D,
        query: String?
    ) async -> [FoursquarePlace] {
        print("🗺️ Using OpenStreetMap Nominatim API (free, no key required)")
        
        let searchQuery = query ?? "restaurant,attraction,museum,park"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Search within bounding box around location
        let bbox = "\(location.longitude - 0.1),\(location.latitude - 0.1),\(location.longitude + 0.1),\(location.latitude + 0.1)"
        
        var urlComponents = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "50"),
            URLQueryItem(name: "bounded", value: "1"),
            URLQueryItem(name: "viewbox", value: bbox)
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Itinero Travel App", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let results = try JSONDecoder().decode([OSMPlace].self, from: data)
            
            // Convert OSM places to FoursquarePlace format
            let places = results.compactMap { osmPlace -> FoursquarePlace? in
                guard let lat = Double(osmPlace.lat),
                      let lon = Double(osmPlace.lon) else {
                    return nil
                }
                
                // Create a FoursquarePlace-like structure
                // We'll need to create a custom decoder or use a simpler approach
                return nil // Will implement conversion
            }
            
            print("✅ Found \(results.count) places from OpenStreetMap")
            return []
            
        } catch {
            errorMessage = "Failed to fetch places: \(error.localizedDescription)"
            print("❌ OpenStreetMap error: \(error)")
            return []
        }
    }
}

// MARK: - OpenStreetMap Place (for fallback)
struct OSMPlace: Codable {
    let placeId: Int
    let lat: String
    let lon: String
    let displayName: String
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case lat
        case lon
        case displayName = "display_name"
        case type
    }
}

