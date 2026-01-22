//
//  ItineraryItem.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

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
        reminderDate: Date? = nil
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
    }
}

