//
//  AITripPlanner.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftUI

@MainActor
class AITripPlanner: ObservableObject {
    static let shared = AITripPlanner()
    
    @Published var suggestions: [TripSuggestion] = []
    @Published var isGenerating = false
    
    private init() {}
    
    func generateSuggestions(
        destination: String,
        duration: Int,
        budget: Double?,
        interests: [String] = []
    ) async {
        isGenerating = true
        defer { isGenerating = false }
        
        // Simulate AI processing (in production, this would call an AI API)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let suggestions = createSmartSuggestions(
            destination: destination,
            duration: duration,
            budget: budget,
            interests: interests
        )
        
        self.suggestions = suggestions
    }
    
    private func createSmartSuggestions(
        destination: String,
        duration: Int,
        budget: Double?,
        interests: [String]
    ) -> [TripSuggestion] {
        var suggestions: [TripSuggestion] = []
        
        // Activity suggestions based on destination
        let activities = getActivitiesForDestination(destination, duration: duration)
        suggestions.append(contentsOf: activities)
        
        // Budget recommendations
        if let budget = budget {
            let budgetTip = TripSuggestion(
                type: .budget,
                title: "Budget Optimization",
                description: "With a budget of \(formatCurrency(budget)), consider allocating:\n• Accommodation: \(formatCurrency(budget * 0.4))\n• Food: \(formatCurrency(budget * 0.3))\n• Activities: \(formatCurrency(budget * 0.2))\n• Emergency: \(formatCurrency(budget * 0.1))",
                priority: .high
            )
            suggestions.append(budgetTip)
        }
        
        // Time-based suggestions
        if duration <= 3 {
            suggestions.append(TripSuggestion(
                type: .tip,
                title: "Short Trip Tips",
                description: "For a \(duration)-day trip, focus on 2-3 key experiences. Book accommodations in advance and plan activities close to each other.",
                priority: .medium
            ))
        } else if duration >= 7 {
            suggestions.append(TripSuggestion(
                type: .tip,
                title: "Extended Stay Tips",
                description: "With \(duration) days, you can explore multiple areas. Consider a mix of guided tours and free exploration time.",
                priority: .medium
            ))
        }
        
        // Interest-based suggestions
        if interests.contains("culture") {
            suggestions.append(TripSuggestion(
                type: .activity,
                title: "Cultural Experiences",
                description: "Visit local museums, historical sites, and attend cultural events. Check local event calendars for festivals during your stay.",
                priority: .high
            ))
        }
        
        if interests.contains("adventure") {
            suggestions.append(TripSuggestion(
                type: .activity,
                title: "Adventure Activities",
                description: "Look for hiking trails, water sports, or adventure parks. Book in advance during peak seasons.",
                priority: .high
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func getActivitiesForDestination(_ destination: String, duration: Int) -> [TripSuggestion] {
        let destinationLower = destination.lowercased()
        var activities: [TripSuggestion] = []
        
        // City-specific suggestions
        if destinationLower.contains("paris") {
            activities.append(TripSuggestion(
                type: .activity,
                title: "Eiffel Tower Visit",
                description: "Book tickets in advance. Best views at sunset. Consider the Seine river cruise.",
                priority: .high
            ))
        } else if destinationLower.contains("tokyo") {
            activities.append(TripSuggestion(
                type: .activity,
                title: "Shibuya & Harajuku",
                description: "Experience modern Tokyo culture. Visit Meiji Shrine and explore local street food.",
                priority: .high
            ))
        } else if destinationLower.contains("new york") || destinationLower.contains("nyc") {
            activities.append(TripSuggestion(
                type: .activity,
                title: "Central Park & Museums",
                description: "Explore Central Park, visit the MET or MoMA. Consider a Broadway show.",
                priority: .high
            ))
        } else {
            // Generic suggestions
            activities.append(TripSuggestion(
                type: .activity,
                title: "Local Exploration",
                description: "Research top attractions, local restaurants, and hidden gems. Check reviews and book popular spots in advance.",
                priority: .medium
            ))
        }
        
        return activities
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

struct TripSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Priority
    
    enum SuggestionType {
        case activity
        case tip
        case budget
        case accommodation
        case restaurant
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    var icon: String {
        switch type {
        case .activity: return "star.fill"
        case .tip: return "lightbulb.fill"
        case .budget: return "dollarsign.circle.fill"
        case .accommodation: return "bed.double.fill"
        case .restaurant: return "fork.knife"
        }
    }
    
    var color: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}


