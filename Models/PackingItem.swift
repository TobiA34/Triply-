//
//  PackingItem.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class PackingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var isPacked: Bool
    var category: String
    var quantity: Int
    var estimatedWeight: Double?
    var notes: String
    var photoData: Data?
    var bagName: String?
    var isEssential: Bool
    var order: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        isPacked: Bool = false,
        category: String = "General",
        order: Int = 0,
        quantity: Int = 1,
        estimatedWeight: Double? = nil,
        notes: String = "",
        photoData: Data? = nil,
        bagName: String? = nil,
        isEssential: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isPacked = isPacked
        self.category = category
        self.order = order
        self.quantity = quantity
        self.estimatedWeight = estimatedWeight
        self.notes = notes
        self.photoData = photoData
        self.bagName = bagName
        self.isEssential = isEssential
    }
}



