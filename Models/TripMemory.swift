//
//  TripMemory.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData
import UIKit

@Model
final class TripMemory {
    @Attribute(.unique) var id: UUID
    var tripId: UUID
    var photoData: Data?
    var caption: String
    var location: String?
    var date: Date
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        tripId: UUID,
        photoData: Data? = nil,
        caption: String = "",
        location: String? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.tripId = tripId
        self.photoData = photoData
        self.caption = caption
        self.location = location
        self.date = date
        self.createdAt = Date()
    }
    
    var image: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
}


