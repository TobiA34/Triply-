//
//  ItineraryItem.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData
import UIKit

@Model
final class ItineraryItem {
    @Attribute(.unique) var id: UUID
    var day: Int
    var date: Date
    var title: String
    var details: String
    var time: String
    var location: String
    var order: Int
    var isBooked: Bool
    var bookingReference: String
    var reminderDate: Date?
    var category: String
    var estimatedCost: Double?
    var estimatedDuration: Int?
    var photoData: Data?
    var sourceURL: String?
    var travelTimeFromPrevious: Int?
    
    @Relationship(deleteRule: .nullify) var documents: [TripDocument]?
    
    init(
        id: UUID = UUID(),
        day: Int,
        date: Date,
        title: String,
        details: String = "",
        time: String = "",
        location: String = "",
        order: Int = 0,
        isBooked: Bool = false,
        bookingReference: String = "",
        reminderDate: Date? = nil,
        category: String = "",
        estimatedCost: Double? = nil,
        estimatedDuration: Int? = nil,
        photoData: Data? = nil,
        sourceURL: String? = nil,
        travelTimeFromPrevious: Int? = nil
    ) {
        self.id = id
        self.day = day
        self.date = date
        self.title = title
        self.details = details
        self.time = time
        self.location = location
        self.order = order
        self.isBooked = isBooked
        self.bookingReference = bookingReference
        self.reminderDate = reminderDate
        self.category = category
        self.estimatedCost = estimatedCost
        self.estimatedDuration = estimatedDuration
        self.photoData = photoData
        self.sourceURL = sourceURL
        self.travelTimeFromPrevious = travelTimeFromPrevious
    }
    
    // Computed property for photo
    var photo: UIImage? {
        guard let photoData = photoData else { return nil }
        return UIImage(data: photoData)
    }
}

