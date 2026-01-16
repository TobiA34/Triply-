//
//  TripModel.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class TripModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var notes: String
    var category: String
    var budget: Double?
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade) var destinations: [DestinationModel]?
    @Relationship(deleteRule: .cascade) var itinerary: [ItineraryItem]?
    @Relationship(deleteRule: .cascade) var expenses: [Expense]?
    @Relationship(deleteRule: .cascade) var packingList: [PackingItem]?
    @Relationship(deleteRule: .cascade) var documents: [TripDocument]?
    @Relationship(deleteRule: .cascade) var documentFolders: [DocumentFolder]?
    
    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        notes: String = "",
        category: String = "General",
        budget: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.category = category
        self.budget = budget
        self.createdAt = Date()
        self.destinations = []
        self.itinerary = []
        self.expenses = []
        self.packingList = []
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var isUpcoming: Bool {
        startDate > Date()
    }
    
    var isPast: Bool {
        endDate < Date()
    }
    
    var isCurrent: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }
}

