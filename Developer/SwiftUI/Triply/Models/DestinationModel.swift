//
//  DestinationModel.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class DestinationModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var notes: String
    var order: Int
    var latitude: Double?
    var longitude: Double?
    
    init(
        id: UUID = UUID(),
        name: String,
        address: String = "",
        notes: String = "",
        order: Int = 0,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.notes = notes
        self.order = order
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}



