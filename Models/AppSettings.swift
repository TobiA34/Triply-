//
//  AppSettings.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    // Use a constant UUID to ensure only one settings instance
    @Attribute(.unique) var id: UUID
    var currencyCode: String
    var currencySymbol: String
    var createdAt: Date
    
    // Singleton ID to ensure only one settings record
    static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    init(
        id: UUID = singletonID,
        currencyCode: String = "USD",
        currencySymbol: String = "$"
    ) {
        self.id = id
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.createdAt = Date()
    }
}

struct Currency: Hashable, Identifiable {
    let id: String // Use code as ID
    let code: String
    let symbol: String
    let name: String
    
    init(code: String, symbol: String, name: String) {
        self.id = code
        self.code = code
        self.symbol = symbol
        self.name = name
    }
    
    static let allCurrencies: [Currency] = [
        Currency(code: "USD", symbol: "$", name: "US Dollar"),
        Currency(code: "EUR", symbol: "€", name: "Euro"),
        Currency(code: "GBP", symbol: "£", name: "British Pound"),
        Currency(code: "JPY", symbol: "¥", name: "Japanese Yen"),
        Currency(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        Currency(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
        Currency(code: "CHF", symbol: "CHF", name: "Swiss Franc"),
        Currency(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
        Currency(code: "INR", symbol: "₹", name: "Indian Rupee"),
        Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
        Currency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
        Currency(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
        Currency(code: "KRW", symbol: "₩", name: "South Korean Won"),
        Currency(code: "MXN", symbol: "Mex$", name: "Mexican Peso"),
        Currency(code: "BRL", symbol: "R$", name: "Brazilian Real"),
        Currency(code: "ZAR", symbol: "R", name: "South African Rand"),
        Currency(code: "RUB", symbol: "₽", name: "Russian Ruble"),
        Currency(code: "SEK", symbol: "kr", name: "Swedish Krona"),
        Currency(code: "NOK", symbol: "kr", name: "Norwegian Krone"),
        Currency(code: "DKK", symbol: "kr", name: "Danish Krone"),
        Currency(code: "PLN", symbol: "zł", name: "Polish Zloty"),
        Currency(code: "TRY", symbol: "₺", name: "Turkish Lira"),
        Currency(code: "AED", symbol: "د.إ", name: "UAE Dirham"),
        Currency(code: "SAR", symbol: "﷼", name: "Saudi Riyal"),
        Currency(code: "THB", symbol: "฿", name: "Thai Baht")
    ]
    
    static func currency(for code: String) -> Currency {
        // Try to get from enhanced currency database first
        if let enhanced = CurrencyDatabase.shared.currency(for: code) {
            return enhanced.legacy
        }
        // Fallback to old list
        return allCurrencies.first { $0.code == code } ?? Currency(code: "USD", symbol: "$", name: "US Dollar")
    }
}

