//
//  SmartTripTemplate.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import SwiftData

@Model
final class SmartTripTemplate: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var destination: String
    var details: String
    var category: String
    var icon: String
    var colorHex: String
    var suggestedDuration: Int // days
    var suggestedBudget: Double?
    var suggestedDestinations: [String] // Destination names
    var suggestedItinerary: [String] // Activity suggestions
    var suggestedPackingItems: [String] // Packing list items
    var tags: [String]
    var isPro: Bool // Pro-only templates
    var popularity: Int // Vote count
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        destination: String,
        details: String,
        category: String = "General",
        icon: String = "airplane",
        colorHex: String = "#007AFF",
        suggestedDuration: Int = 7,
        suggestedBudget: Double? = nil,
        suggestedDestinations: [String] = [],
        suggestedItinerary: [String] = [],
        suggestedPackingItems: [String] = [],
        tags: [String] = [],
        isPro: Bool = false,
        popularity: Int = 0
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.details = details
        self.category = category
        self.icon = icon
        self.colorHex = colorHex
        self.suggestedDuration = suggestedDuration
        self.suggestedBudget = suggestedBudget
        self.suggestedDestinations = suggestedDestinations
        self.suggestedItinerary = suggestedItinerary
        self.suggestedPackingItems = suggestedPackingItems
        self.tags = tags
        self.isPro = isPro
        self.popularity = popularity
        self.createdAt = Date()
    }
}








