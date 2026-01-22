//
//  TripDocument.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class TripDocument {
    @Attribute(.unique) var id: UUID
    var type: String  // "ticket", "receipt", "reservation", "passport", "other"
    var title: String
    var notes: String
    var fileName: String?
    var fileData: Data?  // Store file data
    var fileURL: String?  // Or store file URL
    var date: Date?
    var amount: Double?
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(inverse: \TripModel.documents) var trip: TripModel?
    @Relationship(inverse: \ItineraryItem.documents) var relatedItineraryItem: ItineraryItem?
    @Relationship(inverse: \Expense.documents) var relatedExpense: Expense?
    @Relationship(inverse: \DocumentFolder.documents) var folder: DocumentFolder?
    
    init(
        id: UUID = UUID(),
        type: String,
        title: String,
        notes: String = "",
        fileName: String? = nil,
        fileData: Data? = nil,
        fileURL: String? = nil,
        date: Date? = nil,
        amount: Double? = nil,
        trip: TripModel? = nil,
        relatedItineraryItem: ItineraryItem? = nil,
        relatedExpense: Expense? = nil,
        folder: DocumentFolder? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.notes = notes
        self.fileName = fileName
        self.fileData = fileData
        self.fileURL = fileURL
        self.date = date
        self.amount = amount
        self.createdAt = Date()
        self.updatedAt = Date()
        self.trip = trip
        self.relatedItineraryItem = relatedItineraryItem
        self.relatedExpense = relatedExpense
        self.folder = folder
    }
    
    var icon: String {
        switch type.lowercased() {
        case "ticket": return "ticket.fill"
        case "receipt": return "doc.text.fill"
        case "reservation": return "calendar.badge.clock"
        case "passport": return "person.text.rectangle.fill"
        case "visa": return "doc.badge.ellipsis"
        case "insurance": return "shield.fill"
        default: return "doc.fill"
        }
    }
}

