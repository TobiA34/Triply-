//
//  DocumentFolder.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import SwiftData

@Model
final class DocumentFolder {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String // Hex color string
    var icon: String // SF Symbol name
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(inverse: \TripModel.documentFolders) var trip: TripModel?
    @Relationship(deleteRule: .nullify) var documents: [TripDocument]?
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#007AFF", // Default blue
        icon: String = "folder.fill",
        trip: TripModel? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.updatedAt = Date()
        self.trip = trip
        self.documents = []
    }
    
    var documentCount: Int {
        documents?.count ?? 0
    }
}

