//
//  Destination.swift
//  Triply
//
//  Created on 2024
//

import Foundation

struct Destination: Identifiable, Codable {
    let id: UUID
    var name: String
    var address: String
    var notes: String
    
    init(id: UUID = UUID(), name: String, address: String = "", notes: String = "") {
        self.id = id
        self.name = name
        self.address = address
        self.notes = notes
    }
}



