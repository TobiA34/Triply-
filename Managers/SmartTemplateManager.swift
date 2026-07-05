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
            ),
            
            // PRO: Safari
            SmartTripTemplate(
                name: "Safari Adventure",
                destination: "Kenya & Tanzania",
                details: "Witness the Great Migration, Big Five game drives, and unforgettable African sunsets.",
                category: "Adventure",
                icon: "leaf.fill",
                colorHex: "#C4A35A",
                suggestedDuration: 12,
                suggestedBudget: 5500,
                suggestedDestinations: [
                    "Masai Mara",
                    "Serengeti",
                    "Ngorongoro Crater",
                    "Amboseli",
                    "Lake Nakuru"
                ],
                suggestedItinerary: [
                    "Day 1-2: Arrival Nairobi, city tour",
                    "Day 3-4: Masai Mara game drives",
                    "Day 5: Travel to Serengeti",
                    "Day 6-8: Serengeti safari",
                    "Day 9: Ngorongoro Crater",
                    "Day 10: Amboseli National Park",
                    "Day 11: Lake Nakuru, rhino sanctuary",
                    "Day 12: Departure"
                ],
                suggestedPackingItems: [
                    "Neutral-coloured clothing",
                    "Binoculars",
                    "Sunscreen and hat",
                    "Camera with zoom lens",
                    "Malaria prophylaxis"
                ],
                tags: ["safari", "wildlife", "adventure", "nature"],
                isPro: true
            ),
            
            // PRO: Greek Islands
            SmartTripTemplate(
                name: "Greek Islands Hopping",
                destination: "Greece",
                details: "Santorini sunsets, Mykonos nights, and ancient ruins across the Aegean.",
                category: "Relaxation",
                icon: "water.waves",
                colorHex: "#3498DB",
                suggestedDuration: 10,
                suggestedBudget: 2800,
                suggestedDestinations: [
                    "Santorini",
                    "Mykonos",
                    "Crete",
                    "Athens",
                    "Naxos"
                ],
                suggestedItinerary: [
                    "Day 1-2: Athens, Acropolis and Plaka",
                    "Day 3: Ferry to Mykonos",
                    "Day 4-5: Mykonos beaches and nightlife",
                    "Day 6: Ferry to Santorini",
                    "Day 7-8: Santorini Oia and Fira",
                    "Day 9: Naxos or Crete (optional)",
                    "Day 10: Departure"
                ],
                suggestedPackingItems: [
                    "Swimwear and sandals",
                    "Sunscreen",
                    "Light layers for evening",
                    "Adapter",
                    "Camera"
                ],
                tags: ["beach", "culture", "islands", "romantic"],
                isPro: true
            ),
            
            // PRO: Swiss Alps
            SmartTripTemplate(
                name: "Swiss Alps Explorer",
                destination: "Switzerland",
                details: "Alpine peaks, scenic trains, chocolate, and pristine lakes.",
                category: "Adventure",
                icon: "mountain.2.fill",
                colorHex: "#2ECC71",
                suggestedDuration: 8,
                suggestedBudget: 3200,
                suggestedDestinations: [
                    "Zermatt",
                    "Interlaken",
                    "Lucerne",
                    "Jungfraujoch",
                    "Lake Geneva"
                ],
                suggestedItinerary: [
                    "Day 1: Zurich arrival, Lucerne",
                    "Day 2: Lucerne, Mount Pilatus",
                    "Day 3: Interlaken, Jungfrau region",
                    "Day 4: Jungfraujoch – Top of Europe",
                    "Day 5: Grindelwald or Lauterbrunnen",
                    "Day 6: Zermatt, Matterhorn view",
                    "Day 7: Lake Geneva, Montreux",
                    "Day 8: Departure"
                ],
                suggestedPackingItems: [
                    "Layered clothing",
                    "Sturdy walking shoes",
                    "Swiss Travel Pass",
                    "Sunglasses",
                    "Camera"
                ],
                tags: ["mountains", "train", "hiking", "scenic"],
                isPro: true
            ),
            
            // PRO: Dubai
            SmartTripTemplate(
                name: "Dubai Luxury Escape",
                destination: "Dubai, UAE",
                details: "Skyscrapers, desert safaris, world-class shopping, and ultra-modern luxury.",
                category: "Business",
                icon: "building.2.fill",
                colorHex: "#E74C3C",
                suggestedDuration: 6,
                suggestedBudget: 3500,
                suggestedDestinations: [
                    "Burj Khalifa",
                    "Dubai Mall",
                    "Palm Jumeirah",
                    "Desert Safari",
                    "Dubai Marina"
                ],
                suggestedItinerary: [
                    "Day 1: Arrival, Dubai Mall, Burj Khalifa",
                    "Day 2: Palm Jumeirah, Atlantis",
                    "Day 3: Desert safari, dinner under stars",
                    "Day 4: Old Dubai, souks, creek",
                    "Day 5: Dubai Marina, beach clubs",
                    "Day 6: Last-minute shopping, departure"
                ],
                suggestedPackingItems: [
                    "Smart-casual for dining",
                    "Sunscreen",
                    "Light clothing",
                    "Adapter",
                    "Swimwear"
                ],
                tags: ["luxury", "shopping", "desert", "modern"],
                isPro: true
            ),
            
            // PRO: Patagonia
            SmartTripTemplate(
                name: "Patagonia Trek",
                destination: "Chile & Argentina",
                details: "Torres del Paine, Perito Moreno Glacier, and raw wilderness at the end of the world.",
                category: "Adventure",
                icon: "snowflake",
                colorHex: "#1ABC9C",
                suggestedDuration: 14,
                suggestedBudget: 4500,
                suggestedDestinations: [
                    "Torres del Paine",
                    "Perito Moreno Glacier",
                    "El Chaltén",
                    "Ushuaia",
                    "Bariloche"
                ],
                suggestedItinerary: [
                    "Day 1-2: Buenos Aires, fly to El Calafate",
                    "Day 3-4: Perito Moreno Glacier",
                    "Day 5-7: Torres del Paine trek",
                    "Day 8-9: El Chaltén, Fitz Roy",
                    "Day 10-11: Ushuaia, Tierra del Fuego",
                    "Day 12-13: Bariloche or Punta Arenas",
                    "Day 14: Departure"
                ],
                suggestedPackingItems: [
                    "Hiking boots (broken in)",
                    "Waterproof layers",
                    "Trekking poles",
                    "Headlamp",
                    "Power bank"
                ],
                tags: ["hiking", "glaciers", "wilderness", "photography"],
                isPro: true
            ),
            
            // PRO: Australian East Coast
            SmartTripTemplate(
                name: "Australian East Coast",
                destination: "Australia",
                details: "Sydney to Cairns — beaches, reef, rainforest, and iconic landmarks.",
                category: "Adventure",
                icon: "beach.umbrella.fill",
                colorHex: "#9B59B6",
                suggestedDuration: 14,
                suggestedBudget: 4000,
                suggestedDestinations: [
                    "Sydney",
                    "Byron Bay",
                    "Gold Coast",
                    "Whitsundays",
                    "Great Barrier Reef"
                ],
                suggestedItinerary: [
                    "Day 1-3: Sydney (Opera House, Bondi, Harbour)",
                    "Day 4-5: Byron Bay, surf and relax",
                    "Day 6-7: Gold Coast, theme parks or beach",
                    "Day 8-9: Brisbane or Noosa",
                    "Day 10-11: Whitsundays sailing",
                    "Day 12-13: Cairns, Great Barrier Reef",
                    "Day 14: Departure"
                ],
                suggestedPackingItems: [
                    "Reef-safe sunscreen",
                    "Swimwear",
                    "Reef shoes",
                    "Camera (underwater optional)",
                    "Light clothing"
                ],
                tags: ["beach", "reef", "road-trip", "nature"],
                isPro: true
            ),
            
            // PRO: European Grand Tour
            SmartTripTemplate(
                name: "European Grand Tour",
                destination: "Multi-City Europe",
                details: "Paris, Rome, Barcelona — art, food, and history across three capitals.",
                category: "City",
                icon: "airplane",
                colorHex: "#E67E22",
                suggestedDuration: 12,
                suggestedBudget: 4200,
                suggestedDestinations: [
                    "Paris",
                    "Rome",
                    "Barcelona",
                    "Florence",
                    "Amsterdam"
                ],
                suggestedItinerary: [
                    "Day 1-3: Paris (Louvre, Eiffel Tower, Montmartre)",
                    "Day 4: Travel to Amsterdam",
                    "Day 5: Amsterdam canals and museums",
                    "Day 6: Fly to Rome",
                    "Day 7-9: Rome (Colosseum, Vatican, Trastevere)",
                    "Day 10: Florence day trip",
                    "Day 11: Barcelona (Sagrada Família, Park Güell)",
                    "Day 12: Departure"
                ],
                suggestedPackingItems: [
                    "Comfortable walking shoes",
                    "EU adapter",
                    "Light day bag",
                    "Travel docs (Schengen)",
                    "Camera"
                ],
                tags: ["culture", "art", "food", "multi-city"],
                isPro: true
            ),
            
            // PRO: Japan Multi-City
            SmartTripTemplate(
                name: "Japan Highlights",
                destination: "Japan",
                details: "Tokyo, Kyoto, Osaka — temples, tech, and traditional culture in one trip.",
                category: "City",
                icon: "building.2.fill",
                colorHex: "#E91E63",
                suggestedDuration: 10,
                suggestedBudget: 3800,
                suggestedDestinations: [
                    "Tokyo",
                    "Kyoto",
                    "Osaka",
                    "Mount Fuji",
                    "Nara"
                ],
                suggestedItinerary: [
                    "Day 1-3: Tokyo (Shibuya, Senso-ji, teamLab)",
                    "Day 4: Mount Fuji or Hakone",
                    "Day 5-6: Kyoto (Fushimi Inari, Gion, temples)",
                    "Day 7: Nara day trip",
                    "Day 8-9: Osaka (food, Dotonbori, castle)",
                    "Day 10: Departure"
                ],
                suggestedPackingItems: [
                    "JR Pass (activate on arrival)",
                    "Pocket WiFi",
                    "Comfortable shoes",
                    "Cash (many places cash-only)",
                    "Light bag for day trips"
                ],
                tags: ["culture", "food", "temples", "multi-city"],
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







