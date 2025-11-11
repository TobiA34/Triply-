//
//  WeatherManager.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import CoreLocation

struct WeatherForecast: Identifiable {
    let id: UUID
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let condition: String
    let icon: String
    let humidity: Int
    let precipitation: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        highTemp: Double,
        lowTemp: Double,
        condition: String,
        icon: String = "sun.max",
        humidity: Int = 50,
        precipitation: Double = 0
    ) {
        self.id = id
        self.date = date
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.condition = condition
        self.icon = icon
        self.humidity = humidity
        self.precipitation = precipitation
    }
}

@MainActor
class WeatherManager: ObservableObject {
    static let shared = WeatherManager()
    
    @Published var forecasts: [WeatherForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchWeather(for destination: String, startDate: Date, endDate: Date) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call with mock data
        // In production, integrate with OpenWeatherMap, WeatherKit, or similar
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        var mockForecasts: [WeatherForecast] = []
        var currentDate = startDate
        var dayOffset = 0
        
        while currentDate <= endDate && dayOffset < 5 {
            // Generate realistic mock weather data
            let baseTemp = Double.random(in: 15...30)
            let condition = ["Sunny", "Partly Cloudy", "Cloudy", "Rainy"].randomElement() ?? "Sunny"
            let icon = iconForCondition(condition)
            
            let forecast = WeatherForecast(
                date: currentDate,
                highTemp: baseTemp + Double.random(in: 2...5),
                lowTemp: baseTemp - Double.random(in: 2...5),
                condition: condition,
                icon: icon,
                humidity: Int.random(in: 40...80),
                precipitation: condition == "Rainy" ? Double.random(in: 0.1...5.0) : 0
            )
            
            mockForecasts.append(forecast)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            dayOffset += 1
        }
        
        forecasts = mockForecasts
        isLoading = false
    }
    
    private func iconForCondition(_ condition: String) -> String {
        switch condition.lowercased() {
        case "sunny": return "sun.max.fill"
        case "partly cloudy": return "cloud.sun.fill"
        case "cloudy": return "cloud.fill"
        case "rainy": return "cloud.rain.fill"
        default: return "sun.max.fill"
        }
    }
}

