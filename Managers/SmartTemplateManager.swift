//
//  SmartTemplateManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import SwiftData

@MainActor
class SmartTemplateManager: ObservableObject {
    static let shared = SmartTemplateManager()
    
    @Published var templates: [SmartTripTemplate] = []
    
    private init() {
        loadDefaultTemplates()
    }
    
    func loadDefaultTemplates() {
        templates = [
            // Paris Template
            SmartTripTemplate(
                name: "Paris City Break",
                destination: "Paris, France",
                details: "Explore the City of Light with iconic landmarks, world-class museums, and delicious cuisine.",
                category: "City",
                icon: "building.2.fill",
                colorHex: "#FF6B6B",
                suggestedDuration: 5,
                suggestedBudget: 1500,
                suggestedDestinations: [
                    "Eiffel Tower",
                    "Louvre Museum",
                    "Notre-Dame Cathedral",
                    "Champs-Élysées",
                    "Montmartre"
                ],
                suggestedItinerary: [
                    "Day 1: Arrival, Eiffel Tower visit, Seine River cruise",
                    "Day 2: Louvre Museum, Tuileries Garden, Champs-Élysées",
                    "Day 3: Notre-Dame, Latin Quarter, Montmartre",
                    "Day 4: Versailles day trip",
                    "Day 5: Shopping, local markets, departure"
                ],
                suggestedPackingItems: [
                    "Comfortable walking shoes",
                    "Camera",
                    "Travel adapter",
                    "Light jacket",
                    "Museum pass"
                ],
                tags: ["culture", "art", "romance", "food"],
                isPro: false
            ),
            
            // Tokyo Template
            SmartTripTemplate(
                name: "Tokyo Adventure",
                destination: "Tokyo, Japan",
                details: "Experience the perfect blend of traditional culture and modern innovation in Japan's capital.",
                category: "City",
                icon: "building.2.fill",
                colorHex: "#4ECDC4",
                suggestedDuration: 7,
                suggestedBudget: 2000,
                suggestedDestinations: [
                    "Shibuya Crossing",
                    "Senso-ji Temple",
                    "Tokyo Skytree",
                    "Harajuku",
                    "Tsukiji Fish Market"
                ],
                suggestedItinerary: [
                    "Day 1: Arrival, Shibuya exploration",
                    "Day 2: Senso-ji Temple, Asakusa district",
                    "Day 3: Tokyo Skytree, Sumida River",
                    "Day 4: Harajuku, Meiji Shrine",
                    "Day 5: Tsukiji Market, Ginza shopping",
                    "Day 6: Day trip to Mount Fuji or Nikko",
                    "Day 7: Last-minute shopping, departure"
                ],
                suggestedPackingItems: [
                    "JR Pass",
                    "Pocket WiFi",
                    "Cash (many places cash-only)",
                    "Comfortable shoes",
                    "Portable charger"
                ],
                tags: ["culture", "food", "technology", "shopping"],
                isPro: false
            ),
            
            // Bali Template
            SmartTripTemplate(
                name: "Bali Paradise",
                destination: "Bali, Indonesia",
                details: "Relax on stunning beaches, explore ancient temples, and enjoy world-class resorts.",
                category: "Beach",
                icon: "beach.umbrella.fill",
                colorHex: "#95E1D3",
                suggestedDuration: 10,
                suggestedBudget: 1800,
                suggestedDestinations: [
                    "Ubud Monkey Forest",
                    "Tanah Lot Temple",
                    "Seminyak Beach",
                    "Tegallalang Rice Terraces",
                    "Mount Batur"
                ],
                suggestedItinerary: [
                    "Day 1-2: Arrival, Seminyak beach relaxation",
                    "Day 3: Ubud Monkey Forest, rice terraces",
                    "Day 4: Tanah Lot Temple, sunset viewing",
                    "Day 5: Mount Batur sunrise hike",
                    "Day 6-7: Beach activities, spa treatments",
                    "Day 8: Water temple visits",
                    "Day 9: Local markets, cooking class",
                    "Day 10: Departure"
                ],
                suggestedPackingItems: [
                    "Swimwear",
                    "Sunscreen (high SPF)",
                    "Mosquito repellent",
                    "Light clothing",
                    "Temple-appropriate attire"
                ],
                tags: ["beach", "relaxation", "culture", "nature"],
                isPro: false
            ),
            
            // New York Template
            SmartTripTemplate(
                name: "New York City Experience",
                destination: "New York, USA",
                details: "The city that never sleeps - Broadway shows, world-famous landmarks, and incredible food.",
                category: "City",
                icon: "building.2.fill",
                colorHex: "#F38181",
                suggestedDuration: 6,
                suggestedBudget: 2500,
                suggestedDestinations: [
                    "Statue of Liberty",
                    "Central Park",
                    "Times Square",
                    "Brooklyn Bridge",
                    "Metropolitan Museum"
                ],
                suggestedItinerary: [
                    "Day 1: Arrival, Times Square, Broadway show",
                    "Day 2: Statue of Liberty, Ellis Island",
                    "Day 3: Central Park, Metropolitan Museum",
                    "Day 4: Brooklyn Bridge, DUMBO, Brooklyn Heights",
                    "Day 5: High Line, Chelsea Market, shopping",
                    "Day 6: Last-minute exploration, departure"
                ],
                suggestedPackingItems: [
                    "Comfortable walking shoes",
                    "MetroCard",
                    "Layers (weather changes quickly)",
                    "Camera",
                    "Broadway tickets (book in advance)"
                ],
                tags: ["city", "culture", "entertainment", "shopping"],
                isPro: true
            ),
            
            // Iceland Template
            SmartTripTemplate(
                name: "Iceland Road Trip",
                destination: "Iceland",
                details: "Land of fire and ice — waterfalls, geysers, glaciers, and the Northern Lights.",
                category: "Adventure",
                icon: "mountain.2.fill",
                colorHex: "#AA96DA",
                suggestedDuration: 10,
                suggestedBudget: 3000,
                suggestedDestinations: [
                    "Golden Circle",
                    "Blue Lagoon",
                    "Jökulsárlón Glacier Lagoon",
                    "Reykjavik",
                    "Northern Lights viewing"
                ],
                suggestedItinerary: [
                    "Day 1-2: Arrival, Reykjavik exploration",
                    "Day 3: Golden Circle (Geysir, Gullfoss, Thingvellir)",
                    "Day 4: Blue Lagoon, Reykjanes Peninsula",
                    "Day 5-6: South Coast drive, waterfalls",
                    "Day 7: Jökulsárlón Glacier Lagoon",
                    "Day 8: Return to Reykjavik",
                    "Day 9: Northern Lights tour",
                    "Day 10: Departure"
                ],
                suggestedPackingItems: [
                    "Warm layers (thermal, fleece, waterproof)",
                    "Waterproof boots",
                    "Camera with tripod",
                    "Car rental (4WD recommended)",
                    "Swimsuit (for hot springs)"
                ],
                tags: ["adventure", "nature", "photography", "road-trip"],
                isPro: true
            )
        ]
    }
    
    func getTemplates(for category: String? = nil, proOnly: Bool = false) -> [SmartTripTemplate] {
        var filtered = templates
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if proOnly {
            filtered = filtered.filter { $0.isPro }
        }
        
        return filtered.sorted { $0.popularity > $1.popularity }
    }
    
    func searchTemplates(query: String) -> [SmartTripTemplate] {
        let lowerQuery = query.lowercased()
        return templates.filter { template in
            template.name.lowercased().contains(lowerQuery) ||
            template.destination.lowercased().contains(lowerQuery) ||
            template.details.lowercased().contains(lowerQuery) ||
            template.tags.contains { $0.lowercased().contains(lowerQuery) }
        }
    }
}







