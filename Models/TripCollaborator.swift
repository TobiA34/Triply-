//
//  TripCollaborator.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class TripCollaborator {
    @Attribute(.unique) var id: UUID
    var tripId: UUID
    var name: String
    var email: String?
    var role: String // "owner", "editor", "viewer"
    var invitedAt: Date
    var joinedAt: Date?
    
    init(
        id: UUID = UUID(),
        tripId: UUID,
        name: String,
        email: String? = nil,
        role: String = "viewer"
    ) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.email = email
        self.role = role
        self.invitedAt = Date()
    }
}


