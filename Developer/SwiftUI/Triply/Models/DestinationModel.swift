//
//  DestinationModel.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class DestinationModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var notes: String
    var order: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        address: String = "",
        notes: String = "",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.notes = notes
        self.order = order
    }
}



