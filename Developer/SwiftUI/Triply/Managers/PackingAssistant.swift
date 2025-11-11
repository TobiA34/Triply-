//
//  PackingAssistant.swift
//  Triply
//
//  Created on 2024
//

import Foundation

struct PackingSuggestion {
    let item: String
    let category: String
    let reason: String
    let priority: Priority
    
    enum Priority {
        case essential
        case recommended
        case optional
    }
}

@MainActor
class PackingAssistant: ObservableObject {
    static let shared = PackingAssistant()
    
    private init() {}
    
    func generateSuggestions(
        for trip: TripModel,
        weatherForecasts: [WeatherForecast]
    ) -> [PackingSuggestion] {
        var suggestions: [PackingSuggestion] = []
        
        // Analyze weather
        let avgTemp = weatherForecasts.isEmpty ? 20.0 : 
            weatherForecasts.map { ($0.highTemp + $0.lowTemp) / 2 }.reduce(0, +) / Double(weatherForecasts.count)
        let hasRain = weatherForecasts.contains { $0.precipitation > 0 }
        let isHot = avgTemp > 25
        let isCold = avgTemp < 10
        let duration = trip.duration
        
        // Essential items (always)
        suggestions.append(contentsOf: [
            PackingSuggestion(item: "Passport/ID", category: "Documents", reason: "Required for travel", priority: .essential),
            PackingSuggestion(item: "Phone Charger", category: "Electronics", reason: "Essential device", priority: .essential),
            PackingSuggestion(item: "Wallet", category: "Essentials", reason: "Money and cards", priority: .essential),
            PackingSuggestion(item: "Medications", category: "Health", reason: "Personal medications", priority: .essential)
        ])
        
        // Weather-based clothing
        if isHot {
            suggestions.append(PackingSuggestion(item: "Lightweight Clothing", category: "Clothing", reason: "Hot weather expected", priority: .essential))
            suggestions.append(PackingSuggestion(item: "Sunscreen", category: "Health", reason: "Protection from sun", priority: .essential))
            suggestions.append(PackingSuggestion(item: "Hat", category: "Accessories", reason: "Sun protection", priority: .recommended))
        }
        
        if isCold {
            suggestions.append(PackingSuggestion(item: "Warm Jacket", category: "Clothing", reason: "Cold weather expected", priority: .essential))
            suggestions.append(PackingSuggestion(item: "Gloves", category: "Accessories", reason: "Cold protection", priority: .recommended))
            suggestions.append(PackingSuggestion(item: "Scarf", category: "Accessories", reason: "Warmth", priority: .optional))
        }
        
        if hasRain {
            suggestions.append(PackingSuggestion(item: "Umbrella", category: "Accessories", reason: "Rain expected", priority: .essential))
            suggestions.append(PackingSuggestion(item: "Waterproof Jacket", category: "Clothing", reason: "Rain protection", priority: .recommended))
        }
        
        // Duration-based items
        if duration > 7 {
            suggestions.append(PackingSuggestion(item: "Laundry Detergent", category: "Essentials", reason: "Long trip", priority: .recommended))
        }
        
        if duration > 3 {
            suggestions.append(PackingSuggestion(item: "Extra Underwear", category: "Clothing", reason: "Multi-day trip", priority: .essential))
        }
        
        // Category-based
        if trip.category == "Business" {
            suggestions.append(PackingSuggestion(item: "Business Attire", category: "Clothing", reason: "Business trip", priority: .essential))
        }
        
        if trip.category == "Adventure" {
            suggestions.append(PackingSuggestion(item: "Comfortable Shoes", category: "Footwear", reason: "Active trip", priority: .essential))
        }
        
        // General recommendations
        suggestions.append(contentsOf: [
            PackingSuggestion(item: "Toothbrush & Toothpaste", category: "Toiletries", reason: "Personal hygiene", priority: .essential),
            PackingSuggestion(item: "Travel Adapter", category: "Electronics", reason: "International travel", priority: .recommended),
            PackingSuggestion(item: "First Aid Kit", category: "Health", reason: "Safety", priority: .recommended),
            PackingSuggestion(item: "Travel Insurance Documents", category: "Documents", reason: "Safety", priority: .recommended)
        ])
        
        return suggestions
    }
}



