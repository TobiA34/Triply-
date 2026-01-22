//
//  CurrencyConverter.swift
//  Itinero
//
//  Created on 2024
//

import Foundation

struct ExchangeRate {
    let fromCurrency: String
    let toCurrency: String
    let rate: Double
    let lastUpdated: Date
}

struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}

@MainActor
class CurrencyConverter: ObservableObject {
    static let shared = CurrencyConverter()
    
    @Published var exchangeRates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    // Cache rates for offline use
    private let cacheKey = "currencyRatesCache"
    private let cacheDateKey = "currencyRatesCacheDate"
    private let cacheExpiryHours: TimeInterval = 24 // Cache for 24 hours
    
    // Fallback rates if API fails
    private let fallbackRates: [String: Double] = [
        "EUR": 0.92, "GBP": 0.79, "JPY": 150.0, "AUD": 1.52, "CAD": 1.35,
        "CHF": 0.88, "CNY": 7.25, "INR": 83.0, "SGD": 1.34, "HKD": 7.82,
        "NZD": 1.62, "KRW": 1320.0, "MXN": 17.0, "BRL": 4.95, "ZAR": 18.5,
        "RUB": 92.0, "SEK": 10.5, "NOK": 10.8, "DKK": 6.85, "PLN": 4.0,
        "TRY": 32.0, "AED": 3.67, "SAR": 3.75, "THB": 35.0
    ]
    
    private init() {
        loadCachedRates()
    }
    
    // Load cached rates from UserDefaults
    private func loadCachedRates() {
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedRates = try? JSONDecoder().decode([String: Double].self, from: cachedData),
           let cacheDate = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
           Date().timeIntervalSince(cacheDate) < cacheExpiryHours * 3600 {
            exchangeRates = cachedRates
            lastUpdated = cacheDate
            print("✅ Loaded cached currency rates")
        } else {
            // Use fallback rates
            exchangeRates = fallbackRates
            print("⚠️ Using fallback currency rates")
        }
    }
    
    // Cache rates to UserDefaults
    private func cacheRates(_ rates: [String: Double]) {
        if let encoded = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
        }
    }
    
    // Fetch latest rates from exchangerate-api.com (free, no API key needed)
    func fetchLatestRates(baseCurrency: String = "USD") async {
        isLoading = true
        errorMessage = nil
        
        // Use exchangerate-api.com free API (no key required)
        let urlString = "https://api.exchangerate-api.com/v4/latest/\(baseCurrency)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decoder = JSONDecoder()
            let exchangeResponse = try decoder.decode(ExchangeRateResponse.self, from: data)
            
            // Convert rates to dictionary
            exchangeRates = exchangeResponse.rates
            lastUpdated = Date()
            
            // Cache the rates
            cacheRates(exchangeRates)
            
            print("✅ Fetched latest currency rates from API")
            isLoading = false
            
        } catch {
            print("❌ Failed to fetch currency rates: \(error)")
            errorMessage = "Failed to fetch rates. Using cached data."
            
            // Try to load cached rates
            loadCachedRates()
            
            // If no cache, use fallback
            if exchangeRates.isEmpty {
                exchangeRates = fallbackRates
            }
            
            isLoading = false
        }
    }
    
    func convert(amount: Double, from: String, to: String) -> Double {
        guard amount > 0 else { return 0 }
        if from == to { return amount }
        
        // If from USD, multiply by rate
        if from == "USD" {
            if let rate = exchangeRates[to] {
                return amount * rate
            }
            return amount // Fallback if rate not found
        }
        
        // If to USD, divide by rate
        if to == "USD" {
            if let rate = exchangeRates[from] {
                return amount / rate
            }
            return amount // Fallback if rate not found
        }
        
        // Convert via USD (from -> USD -> to)
        let usdAmount: Double
        if let fromRate = exchangeRates[from] {
            usdAmount = amount / fromRate
        } else {
            usdAmount = amount // Fallback
        }
        
        if let toRate = exchangeRates[to] {
            return usdAmount * toRate
        }
        
        return usdAmount // Fallback
    }
    
    func formatConverted(amount: Double, from: String, to: String, symbol: String) -> String {
        let converted = convert(amount: amount, from: from, to: to)
        return "\(symbol)\(String(format: "%.2f", converted))"
    }
    
    // Get exchange rate between two currencies
    func getRate(from: String, to: String) -> Double? {
        if from == to { return 1.0 }
        
        if from == "USD" {
            return exchangeRates[to]
        }
        
        if to == "USD" {
            if let rate = exchangeRates[from] {
                return 1.0 / rate
            }
            return nil
        }
        
        // Convert via USD
        guard let fromRate = exchangeRates[from],
              let toRate = exchangeRates[to] else {
            return nil
        }
        
        return (1.0 / fromRate) * toRate
    }
    
    // Refresh rates if cache is stale
    func refreshIfNeeded(baseCurrency: String = "USD") async {
        if let lastUpdate = lastUpdated {
            let hoursSinceUpdate = Date().timeIntervalSince(lastUpdate) / 3600
            if hoursSinceUpdate >= cacheExpiryHours {
                await fetchLatestRates(baseCurrency: baseCurrency)
            }
        } else {
            await fetchLatestRates(baseCurrency: baseCurrency)
        }
    }
}

