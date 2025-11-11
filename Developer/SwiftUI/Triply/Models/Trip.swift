//
//  Trip.swift
//  Triply
//
//  Created on 2024
//

import Foundation

struct Trip: Identifiable, Codable {
    let id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var destinations: [Destination]
    var notes: String
    
    init(id: UUID = UUID(), name: String, startDate: Date, endDate: Date, destinations: [Destination] = [], notes: String = "") {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.destinations = destinations
        self.notes = notes
    }
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}



