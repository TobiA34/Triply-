//
//  AffiliateManager.swift
//  Itinero
//
//  Manages affiliate links for hotels, flights, activities, and car rentals
//

import Foundation
import SwiftUI

class AffiliateManager {
    static let shared = AffiliateManager()
    
    // MARK: - Affiliate Partner IDs
    // Replace these with your actual affiliate IDs from each partner
    
    // Booking.com
    private let bookingComAffiliateID = "YOUR_BOOKING_COM_AFFILIATE_ID"
    
    // Hotels.com
    private let hotelsComAffiliateID = "YOUR_HOTELS_COM_AFFILIATE_ID"
    
    // Skyscanner
    private let skyscannerAffiliateID = "YOUR_SKYSCANNER_AFFILIATE_ID"
    
    // GetYourGuide (Activities)
    private let getYourGuideAffiliateID = "YOUR_GETYOURGUIDE_AFFILIATE_ID"
    
    // Viator (Activities)
    private let viatorAffiliateID = "YOUR_VIATOR_AFFILIATE_ID"
    
    // Rentalcars.com
    private let rentalCarsAffiliateID = "YOUR_RENTALCARS_AFFILIATE_ID"
    
    private init() {}
    
    // MARK: - Hotel Booking Links
    
    func bookingComLink(destination: String, checkIn: Date? = nil, checkOut: Date? = nil) -> URL? {
        var components = URLComponents(string: "https://www.booking.com/searchresults.html")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "ss", value: destination),
            URLQueryItem(name: "aid", value: bookingComAffiliateID)
        ]
        
        if let checkIn = checkIn {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "checkin_monthday", value: formatter.string(from: checkIn)))
        }
        
        if let checkOut = checkOut {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "checkout_monthday", value: formatter.string(from: checkOut)))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    func hotelsComLink(destination: String, checkIn: Date? = nil, checkOut: Date? = nil) -> URL? {
        var components = URLComponents(string: "https://www.hotels.com/search.do")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q-destination", value: destination),
            URLQueryItem(name: "affiliate_id", value: hotelsComAffiliateID)
        ]
        
        if let checkIn = checkIn, let checkOut = checkOut {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "q-check-in", value: formatter.string(from: checkIn)))
            queryItems.append(URLQueryItem(name: "q-check-out", value: formatter.string(from: checkOut)))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Flight Booking Links
    
    func skyscannerLink(origin: String, destination: String, departureDate: Date? = nil) -> URL? {
        var components = URLComponents(string: "https://www.skyscanner.com/transport/flights")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "affiliate_id", value: skyscannerAffiliateID)
        ]
        
        if let date = departureDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "departure", value: formatter.string(from: date)))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Activity Booking Links
    
    func getYourGuideLink(destination: String, activity: String? = nil) -> URL? {
        var components = URLComponents(string: "https://www.getyourguide.com/s")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "q", value: activity ?? destination),
            URLQueryItem(name: "aid", value: getYourGuideAffiliateID)
        ]
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    func viatorLink(destination: String, activity: String? = nil) -> URL? {
        var components = URLComponents(string: "https://www.viator.com/searchResults/all")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "text", value: activity ?? destination),
            URLQueryItem(name: "aid", value: viatorAffiliateID)
        ]
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Car Rental Links
    
    func rentalCarsLink(pickupLocation: String, dropoffLocation: String? = nil, pickupDate: Date? = nil) -> URL? {
        var components = URLComponents(string: "https://www.rentalcars.com/SearchResults.do")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pickupLocation", value: pickupLocation),
            URLQueryItem(name: "affiliate_id", value: rentalCarsAffiliateID)
        ]
        
        if let dropoff = dropoffLocation {
            queryItems.append(URLQueryItem(name: "dropoffLocation", value: dropoff))
        }
        
        if let date = pickupDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "pickupDate", value: formatter.string(from: date)))
        }
        
        components?.queryItems = queryItems
        return components?.url
    }
    
    // MARK: - Generic Booking Button
    
    func openBookingLink(_ url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Booking Button View

struct BookingButton: View {
    let title: String
    let icon: String
    let color: Color
    let url: URL?
    
    var body: some View {
        Button {
            AffiliateManager.shared.openBookingLink(url)
        } label: {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

