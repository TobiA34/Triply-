//
//  WeatherForecastView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct WeatherForecastView: View {
    let trip: TripModel
    @StateObject private var weatherManager = WeatherManager.shared
    @State private var selectedDestination: DestinationModel?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Destination Selector
                if let destinations = trip.destinations, !destinations.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(destinations) { destination in
                                Button(action: {
                                    selectedDestination = destination
                                    Task {
                                        await weatherManager.fetchWeather(
                                            for: destination.name,
                                            startDate: trip.startDate,
                                            endDate: trip.endDate
                                        )
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                        Text(destination.name)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(selectedDestination?.id == destination.id ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedDestination?.id == destination.id ? Color.blue : Color(.systemGray5))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if weatherManager.isLoading {
                    ProgressView("Loading weather...")
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let error = weatherManager.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Weather unavailable")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if weatherManager.forecasts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cloud.sun")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a destination to see weather")
                            .font(.headline)
                        Text("Weather forecast will show 5-day predictions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    // Forecast Cards
                    ForEach(weatherManager.forecasts) { forecast in
                        WeatherCardView(forecast: forecast)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Weather Forecast")
        .onAppear {
            // Auto-load weather for first destination
            if selectedDestination == nil,
               let firstDestination = trip.destinations?.first {
                selectedDestination = firstDestination
                Task {
                    await weatherManager.fetchWeather(
                        for: firstDestination.name,
                        startDate: trip.startDate,
                        endDate: trip.endDate
                    )
                }
            }
        }
    }
}

struct WeatherCardView: View {
    let forecast: WeatherForecast
    
    var body: some View {
        HStack(spacing: 16) {
            // Date
            VStack(alignment: .leading, spacing: 4) {
                Text(forecast.date, style: .date)
                    .font(.headline)
                Text(forecast.date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Icon
            Image(systemName: forecast.icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60)
            
            // Condition
            VStack(alignment: .leading, spacing: 4) {
                Text(forecast.condition)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Label("\(Int(forecast.precipitation))mm", systemImage: "drop.fill")
                        .font(.caption)
                    Label("\(forecast.humidity)%", systemImage: "humidity")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Temperature
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(forecast.highTemp))°")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("\(Int(forecast.lowTemp))°")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        WeatherForecastView(trip: TripModel(
            name: "Test Trip",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        ))
    }
}

