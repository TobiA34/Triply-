//
//  TripEnums.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftUI

enum TripPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "star"
        case .medium: return "star.fill"
        case .high: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

enum TravelMode: String, Codable, CaseIterable {
    case flight = "flight"
    case car = "car"
    case train = "train"
    case bus = "bus"
    case cruise = "cruise"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .flight: return "Flight"
        case .car: return "Car"
        case .train: return "Train"
        case .bus: return "Bus"
        case .cruise: return "Cruise"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .car: return "car.fill"
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .cruise: return "ferry.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum AccommodationType: String, Codable, CaseIterable {
    case hotel = "hotel"
    case airbnb = "airbnb"
    case hostel = "hostel"
    case resort = "resort"
    case camping = "camping"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .hotel: return "Hotel"
        case .airbnb: return "Airbnb"
        case .hostel: return "Hostel"
        case .resort: return "Resort"
        case .camping: return "Camping"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .hotel: return "bed.double.fill"
        case .airbnb: return "house.fill"
        case .hostel: return "building.2.fill"
        case .resort: return "beach.umbrella.fill"
        case .camping: return "tent.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum WeatherPreference: String, Codable, CaseIterable {
    case any = "any"
    case sunny = "sunny"
    case moderate = "moderate"
    case cold = "cold"
    
    var displayName: String {
        switch self {
        case .any: return "Any"
        case .sunny: return "Sunny"
        case .moderate: return "Moderate"
        case .cold: return "Cold"
        }
    }
}


