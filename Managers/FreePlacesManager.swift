//
//  FreePlacesManager.swift
//  Itinero
//
//  Free places API using OpenStreetMap Nominatim - No API key required!
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Free Place Model
struct FreePlace: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let location: CLLocationCoordinate2D
    let category: String
    let type: String?
    
    // Custom initializer for Overpass API
    init(id: String, name: String, address: String, location: CLLocationCoordinate2D, category: String, type: String?) {
        self.id = id
        self.name = name
        self.address = address
        self.location = location
        self.category = category
        self.type = type
    }
    
    // Decodable for Nominatim API
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case lat
        case lon
        case displayName = "display_name"
        case type
        case name
        case address
    }
    
    // Custom Equatable
    static func == (lhs: FreePlace, rhs: FreePlace) -> Bool {
        return lhs.id == rhs.id
    }
}

extension FreePlace: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Use place_id as id
        let placeId = try container.decode(Int.self, forKey: .placeId)
        id = "\(placeId)"
        
        // Decode coordinates
        let latString = try container.decode(String.self, forKey: .lat)
        let lonString = try container.decode(String.self, forKey: .lon)
        guard let lat = Double(latString), let lon = Double(lonString) else {
            throw DecodingError.dataCorruptedError(forKey: .lat, in: container, debugDescription: "Invalid coordinates")
        }
        location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        // Decode name - try name field first, then extract from display_name
        if let nameValue = try? container.decodeIfPresent(String.self, forKey: .name), !nameValue.isEmpty {
            name = nameValue
        } else {
            let displayName = try container.decode(String.self, forKey: .displayName)
            // Extract first part of display_name (usually the name)
            name = displayName.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? displayName
        }
        
        // Decode address (display_name without the name)
        let displayName = try container.decode(String.self, forKey: .displayName)
        let components = displayName.components(separatedBy: ",")
        if components.count > 1 {
            address = components.dropFirst().joined(separator: ", ").trimmingCharacters(in: .whitespaces)
        } else {
            address = displayName
        }
        
        // Decode type/category
        type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // Map OSM types to our categories
        let typeLower = (type ?? "").lowercased()
        if typeLower.contains("restaurant") || typeLower.contains("cafe") || typeLower.contains("food") {
            category = "Restaurant"
        } else if typeLower.contains("museum") || typeLower.contains("gallery") {
            category = "Museum"
        } else if typeLower.contains("park") || typeLower.contains("garden") {
            category = "Park"
        } else if typeLower.contains("shop") || typeLower.contains("mall") {
            category = "Shopping"
        } else if typeLower.contains("hotel") || typeLower.contains("lodging") {
            category = "Hotel"
        } else if typeLower.contains("bar") || typeLower.contains("pub") || typeLower.contains("nightclub") {
            category = "Nightlife"
        } else if typeLower.contains("attraction") || typeLower.contains("tourism") || typeLower.contains("monument") {
            category = "Attraction"
        } else {
            category = "Activity"
        }
    }
}

// MARK: - Free Places Manager
@MainActor
class FreePlacesManager: ObservableObject {
    static let shared = FreePlacesManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Search Nearby Places (OpenStreetMap - Free, No API Key!)
    func searchNearby(
        location: CLLocationCoordinate2D,
        radius: Int = 5000,
        category: String? = nil,
        query: String? = nil,
        offset: Int = 0,
        limit: Int = 20
    ) async -> [FreePlace] {
        isLoading = true
        defer { isLoading = false }
        
        let start = Date()
        
        // Performance optimization:
        // Overpass queries can be slow and return a large payload.
        // For a snappier UX we go straight to Nominatim with a smaller limit
        // and tight bounding box, which is usually fast enough.
        let results = await searchWithNominatim(
            location: location,
            radius: radius,
            category: category,
            query: query,
            offset: offset,
            limit: limit
        )

        // Ensure the loading indicator is visible long enough to notice,
        // but don't artificially slow down fast results.
        let elapsed = Date().timeIntervalSince(start)
        if elapsed < 0.2 {
            let remaining = 0.2 - elapsed
            let nanos = UInt64(remaining * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
        }
        
        return results
    }
    
    // MARK: - Overpass API Search (Better for POI searches)
    private func searchWithOverpassAPI(
        location: CLLocationCoordinate2D,
        radius: Int,
        category: String?,
        query: String?
    ) async -> [FreePlace] {
        // Overpass API query to find nearby amenities
        let radiusMeters = radius
        let lat = location.latitude
        let lon = location.longitude
        
        // Build amenity types based on category
        let amenityTypes = getAmenityTypes(for: category)
        
        // Simplified and more reliable Overpass QL query
        // Using simpler syntax that's guaranteed to work
        let overpassQuery = """
        [out:json][timeout:25];
        (
          node["tourism"](around:\(radiusMeters),\(lat),\(lon));
          way["tourism"](around:\(radiusMeters),\(lat),\(lon));
          node["historic"](around:\(radiusMeters),\(lat),\(lon));
          way["historic"](around:\(radiusMeters),\(lat),\(lon));
          node["amenity"~"restaurant|cafe|fast_food|bar|pub|museum|gallery|theatre|cinema"](around:\(radiusMeters),\(lat),\(lon));
          way["amenity"~"restaurant|cafe|fast_food|bar|pub|museum|gallery|theatre|cinema"](around:\(radiusMeters),\(lat),\(lon));
        );
        out center meta;
        """
        
        // Use the most reliable Overpass server
        // Start with the official one for better reliability
        guard let url = URL(string: "https://overpass-api.de/api/interpreter") else {
            errorMessage = "Invalid URL"
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Itinero Travel App (iOS)", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "POST"
        request.httpBody = overpassQuery.data(using: .utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30  // Increased timeout for reliability
        request.cachePolicy = .reloadIgnoringLocalCacheData  // Always get fresh data
        
        do {
            print("🔍 Searching Overpass API for places near: \(lat), \(lon)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Overpass API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 429 {
                    errorMessage = "API rate limit reached. Please wait a moment and try again later."
                    print("❌ Rate limit hit on Overpass API")
                    return []
                } else if httpResponse.statusCode == 504 || httpResponse.statusCode == 503 {
                    errorMessage = "Service temporarily unavailable. Please try again in a few moments."
                    print("⚠️ Service unavailable: \(httpResponse.statusCode)")
                    return []
                } else if httpResponse.statusCode != 200 {
                    print("⚠️ Overpass returned status \(httpResponse.statusCode)")
                    // Try to parse error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMsg = errorData["error"] as? String {
                        errorMessage = errorMsg
                    }
                    return []
                }
            }
            
            // Parse Overpass JSON response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Failed to parse Overpass JSON")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString.prefix(1000))")
                }
                // Fallback to Nominatim
                return await searchWithNominatim(location: location, radius: radius, category: category, query: query)
            }
            
            // Check for error in response
            if let errorMsg = json["error"] as? String {
                print("❌ Overpass API error: \(errorMsg)")
                errorMessage = "API error: \(errorMsg)"
                // Fallback to Nominatim
                return await searchWithNominatim(location: location, radius: radius, category: category, query: query)
            }
            
            guard let elements = json["elements"] as? [[String: Any]] else {
                print("❌ No 'elements' in Overpass response")
                print("📄 Response keys: \(json.keys.joined(separator: ", "))")
                // Fallback to Nominatim
                return await searchWithNominatim(location: location, radius: radius, category: category, query: query)
            }
            
            print("📊 Overpass returned \(elements.count) raw elements")
            
            // Pre-allocate capacity for better performance
            var places: [FreePlace] = []
            places.reserveCapacity(min(elements.count, 100))
            
            // Parse all elements
            var parseErrors = 0
            for element in elements {
                if let place = parseOverpassElement(element) {
                    places.append(place)
                } else {
                    parseErrors += 1
                }
            }
            
            if parseErrors > 0 {
                print("⚠️ Failed to parse \(parseErrors) out of \(elements.count) elements")
            }
            
            print("✅ Successfully parsed \(places.count) places from \(elements.count) elements")
            
            // If we got no results, try Nominatim
            if places.isEmpty {
                print("⚠️ Overpass returned no valid places, trying Nominatim...")
                return await searchWithNominatim(location: location, radius: radius, category: category, query: query)
            }
            
            errorMessage = nil
            return places
            
        } catch {
            print("❌ Overpass API error: \(error.localizedDescription)")
            errorMessage = "Network error: \(error.localizedDescription)"
            // Fallback to Nominatim
            print("🔄 Falling back to Nominatim...")
            return await searchWithNominatim(location: location, radius: radius, category: category, query: query)
        }
    }
    
    // MARK: - Nominatim Fallback (with pagination support)
    private func searchWithNominatim(
        location: CLLocationCoordinate2D,
        radius: Int,
        category: String?,
        query: String?,
        offset: Int = 0,
        limit: Int = 50
    ) async -> [FreePlace] {
        print("🔍 Using Nominatim API for location: \(location.latitude), \(location.longitude) (offset: \(offset), limit: \(limit))")
        
        // Build a better query - use nearby search which is more reliable
        let searchQuery = query ?? "attraction museum restaurant landmark"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Use nearby search endpoint which is better for location-based searches
        // Nominatim supports pagination via offset parameter
        var urlComponents = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: encodedQuery),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)"),  // Pagination support
            URLQueryItem(name: "bounded", value: "1"),
            URLQueryItem(name: "viewbox", value: "\(location.longitude - 0.1),\(location.latitude + 0.1),\(location.longitude + 0.1),\(location.latitude - 0.1)"),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "extratags", value: "1")
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Itinero Travel App (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20  // Increased timeout for reliability
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            print("🔍 Searching Nominatim for: \(searchQuery)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 Nominatim API Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 429 {
                    errorMessage = "API rate limit reached. Please wait a moment and try again later. OpenStreetMap has a usage policy of 1 request per second."
                    print("❌ Rate limit hit on Nominatim API")
                    return []
                } else if httpResponse.statusCode == 503 {
                    errorMessage = "Service temporarily unavailable. Please try again in a few moments."
                    print("⚠️ Service unavailable: \(httpResponse.statusCode)")
                    return []
                }
            }
            
            let places = try JSONDecoder().decode([FreePlace].self, from: data)
            
            print("✅ Successfully fetched \(places.count) places from Nominatim")
            if places.isEmpty {
                // Treat \"no results\" as a normal (non-error) state.
                // The caller (e.g. DestinationActivitiesView) will show a friendly
                // \"No activities found\" message instead of an error banner.
                print("ℹ️ Nominatim returned empty results for this area")
                errorMessage = nil
            } else {
                errorMessage = nil
            }
            return places
            
        } catch {
            let errorMsg = "Failed to fetch places: \(error.localizedDescription)"
            errorMessage = errorMsg
            print("❌ Nominatim error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Parse Overpass Element (Optimized)
    private func parseOverpassElement(_ element: [String: Any]) -> FreePlace? {
        // Fast path: check type and id first
        guard let type = element["type"] as? String,
              let id = element["id"] as? Int else {
            return nil
        }
        
        // Get coordinates - optimized parsing
        var lat: Double = 0
        var lon: Double = 0
        
        if type == "node" {
            // Fast path for nodes (most common)
            guard let latValue = element["lat"] as? Double,
                  let lonValue = element["lon"] as? Double else {
                return nil
            }
            lat = latValue
            lon = lonValue
        } else if type == "way" {
            // For ways, prefer center (faster than geometry)
            if let center = element["center"] as? [String: Any],
               let latValue = center["lat"] as? Double,
               let lonValue = center["lon"] as? Double {
                lat = latValue
                lon = lonValue
            } else if let geometry = element["geometry"] as? [[String: Any]],
                      let firstPoint = geometry.first,
                      let latValue = firstPoint["lat"] as? Double,
                      let lonValue = firstPoint["lon"] as? Double {
                lat = latValue
                lon = lonValue
            } else {
                return nil
            }
        } else {
            return nil  // Skip relations and other types for speed
        }
        
        // Get tags
        guard let tags = element["tags"] as? [String: Any] else {
            return nil
        }
        
        let name = (tags["name"] as? String) ?? (tags["name:en"] as? String) ?? (tags["name:local"] as? String) ?? "Unnamed Place"
        let amenity = tags["amenity"] as? String ?? ""
        let tourism = tags["tourism"] as? String ?? ""
        let shop = tags["shop"] as? String ?? ""
        let historic = tags["historic"] as? String ?? ""
        let building = tags["building"] as? String ?? ""
        
        // Build address from tags
        var addressParts: [String] = []
        if let street = tags["addr:street"] as? String {
            addressParts.append(street)
        }
        if let city = tags["addr:city"] as? String {
            addressParts.append(city)
        } else if let city = tags["place"] as? String {
            addressParts.append(city)
        }
        let address = addressParts.isEmpty ? "Location" : addressParts.joined(separator: ", ")
        
        // Determine category - prioritize tourist attractions and landmarks
        let category: String
        if !tourism.isEmpty {
            // Tourism tags are most important for attractions
            if tourism.contains("attraction") || tourism.contains("museum") || tourism.contains("gallery") || tourism.contains("monument") || tourism.contains("artwork") || tourism.contains("viewpoint") {
                category = "Attraction"
            } else if tourism.contains("hotel") || tourism.contains("hostel") {
                category = "Hotel"
            } else {
                category = "Attraction"
            }
        } else if !historic.isEmpty {
            // Historic sites are attractions
            category = "Attraction"
        } else if building == "monument" || building == "tower" || name.lowercased().contains("building") || name.lowercased().contains("tower") || name.lowercased().contains("monument") {
            // Famous buildings and monuments
            category = "Attraction"
        } else if !amenity.isEmpty {
            if amenity.contains("restaurant") || amenity.contains("cafe") || amenity.contains("food") {
                category = "Restaurant"
            } else if amenity.contains("museum") || amenity.contains("gallery") {
                category = "Museum"
            } else if amenity.contains("bar") || amenity.contains("pub") {
                category = "Nightlife"
            } else {
                category = "Activity"
            }
        } else if !shop.isEmpty {
            category = "Shopping"
        } else {
            category = "Activity"
        }
        
        // Create FreePlace using the custom initializer
        return FreePlace(
            id: "\(id)",
            name: name,
            address: address,
            location: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            category: category,
            type: !tourism.isEmpty ? tourism : (!historic.isEmpty ? historic : amenity)
        )
    }
    
    // MARK: - Helper
    private func getAmenityTypes(for category: String?) -> String {
        guard let category = category else {
            return "restaurant|cafe|fast_food|bar|pub|museum|gallery|park|shop|hotel"
        }
        
        switch category.lowercased() {
        case "restaurant", "food":
            return "restaurant|cafe|fast_food|bar|pub"
        case "museum":
            return "museum|gallery"
        case "park":
            return "park"
        case "shopping":
            return "shop|mall"
        case "hotel":
            return "hotel|hostel"
        case "nightlife":
            return "bar|pub|nightclub"
        case "attraction", "tourism":
            // Focus on tourist attractions, landmarks, monuments
            return "attraction|tourism|monument|artwork|viewpoint"
        default:
            return "restaurant|cafe|museum|park|shop"
        }
    }
    
    // MARK: - Search by Category
    func searchByCategory(
        location: CLLocationCoordinate2D,
        category: String,
        radius: Int = 5000
    ) async -> [FreePlace] {
        return await searchNearby(
            location: location,
            radius: radius,
            category: category,
            query: nil
        )
    }
    
    // MARK: - Helper
    private func buildSearchQuery(category: String?) -> String {
        guard let category = category else {
            return "restaurant,attraction,museum,park,shopping"
        }
        
        switch category.lowercased() {
        case "restaurant", "food":
            return "restaurant,cafe,food"
        case "museum":
            return "museum,gallery"
        case "park":
            return "park,garden"
        case "shopping":
            return "shop,shopping,mall"
        case "hotel":
            return "hotel,lodging"
        case "nightlife":
            return "bar,pub,nightclub"
        case "attraction", "tourism":
            return "attraction,tourism,monument"
        default:
            return "restaurant,attraction,museum,park"
        }
    }
}

