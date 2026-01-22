//
//  Country.swift
//  Itinero
//
//  Country model with comprehensive country list
//

import Foundation
import SwiftUI

struct Country: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let code: String // ISO 3166-1 alpha-2
    let flag: String // Emoji flag
    let region: String
    
    /// Country name (localization removed)
    var localizedName: String {
        return name
    }
    
    /// Localized region name
    var localizedRegion: String { region }
    
    var displayName: String {
        "\(flag) \(localizedName)"
    }
}

// MARK: - Country Manager
class CountryManager: ObservableObject {
    static let shared = CountryManager()
    
    @Published var countries: [Country] = []
    
    private init() {
        loadCountries()
    }
    
    private func loadCountries() {
        // Limited to 5 most popular travel destinations
        let allCountries = [
            Country(id: "US", name: "United States", code: "US", flag: "🇺🇸", region: "Americas"),
            Country(id: "GB", name: "United Kingdom", code: "GB", flag: "🇬🇧", region: "Europe"),
            Country(id: "FR", name: "France", code: "FR", flag: "🇫🇷", region: "Europe"),
            Country(id: "JP", name: "Japan", code: "JP", flag: "🇯🇵", region: "Asia"),
            Country(id: "IT", name: "Italy", code: "IT", flag: "🇮🇹", region: "Europe"),
        ]
        // Ensure exactly 5 countries
        countries = Array(allCountries.prefix(5))
        countries.sort { $0.name < $1.name }
    }
    
    func searchCountries(_ query: String) -> [Country] {
        if query.isEmpty {
            return countries
        }
        let lowercased = query.lowercased()
        return countries.filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.localizedName.lowercased().contains(lowercased) ||
            $0.code.lowercased().contains(lowercased) ||
            $0.region.lowercased().contains(lowercased) ||
            $0.localizedRegion.lowercased().contains(lowercased)
        }
    }
    
    func countriesByRegion(_ region: String) -> [Country] {
        countries.filter { $0.region == region }
    }
    
    var regions: [String] {
        Array(Set(countries.map { $0.region })).sorted()
    }
}