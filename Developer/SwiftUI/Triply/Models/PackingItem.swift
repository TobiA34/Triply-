//
//  PackingItem.swift
//  Triply
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
    var order: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        isPacked: Bool = false,
        category: String = "General",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isPacked = isPacked
        self.category = category
        self.order = order
    }
}



