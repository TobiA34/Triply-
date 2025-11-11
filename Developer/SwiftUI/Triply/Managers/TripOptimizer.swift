//
//  TripOptimizer.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import CoreLocation

struct OptimizationSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let potentialSavings: Double?
    let priority: Priority
    
    enum SuggestionType {
        case route
        case cost
        case timing
        case accommodation
    }
    
    enum Priority {
        case high
        case medium
        case low
    }
}

@MainActor
class TripOptimizer: ObservableObject {
    static let shared = TripOptimizer()
    
    private init() {}
    
    func optimizeTrip(_ trip: TripModel) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []
        
        // Route optimization
        if let destinations = trip.destinations, destinations.count > 1 {
            let optimizedRoute = optimizeRoute(destinations: destinations)
            if optimizedRoute != destinations {
                suggestions.append(OptimizationSuggestion(
                    type: .route,
                    title: "Optimize Route",
                    description: "Reordering destinations could save travel time",
                    potentialSavings: nil,
                    priority: .medium
                ))
            }
        }
        
        // Cost optimization
        if let budget = trip.budget, let expenses = trip.expenses {
            let totalSpent = expenses.reduce(0) { $0 + $1.amount }
            let remaining = budget - totalSpent
            
            if remaining < 0 {
                suggestions.append(OptimizationSuggestion(
                    type: .cost,
                    title: "Budget Exceeded",
                    description: "You've exceeded your budget by \(String(format: "%.0f", abs(remaining)))",
                    potentialSavings: abs(remaining),
                    priority: .high
                ))
            } else if remaining < budget * 0.1 {
                suggestions.append(OptimizationSuggestion(
                    type: .cost,
                    title: "Budget Warning",
                    description: "You have less than 10% of budget remaining",
                    potentialSavings: nil,
                    priority: .high
                ))
            }
            
            // Find expensive categories
            let categoryExpenses = Dictionary(grouping: expenses, by: { $0.category })
                .mapValues { $0.reduce(0) { $0 + $1.amount } }
            
            if let maxCategory = categoryExpenses.max(by: { $0.value < $1.value }),
               maxCategory.value > budget * 0.3 {
                suggestions.append(OptimizationSuggestion(
                    type: .cost,
                    title: "High Spending Category",
                    description: "\(maxCategory.key) accounts for \(String(format: "%.0f", (maxCategory.value / budget) * 100))% of budget",
                    potentialSavings: maxCategory.value * 0.2, // Suggest 20% savings
                    priority: .medium
                ))
            }
        }
        
        // Timing optimization
        let duration = trip.duration
        if duration > 14 {
            suggestions.append(OptimizationSuggestion(
                type: .timing,
                title: "Long Trip Duration",
                description: "Consider splitting into multiple shorter trips for better cost management",
                potentialSavings: nil,
                priority: .low
            ))
        }
        
        // Accommodation suggestions
        if let expenses = trip.expenses {
            let accommodationExpenses = expenses.filter { $0.category == "Accommodation" }
            if accommodationExpenses.isEmpty && trip.duration > 1 {
                suggestions.append(OptimizationSuggestion(
                    type: .accommodation,
                    title: "Missing Accommodation",
                    description: "No accommodation expenses recorded. Consider booking in advance for better rates.",
                    potentialSavings: nil,
                    priority: .medium
                ))
            }
        }
        
        return suggestions.sorted { $0.priority == .high && $1.priority != .high }
    }
    
    private func optimizeRoute(destinations: [DestinationModel]) -> [DestinationModel] {
        // Simple optimization: sort by order (in production, use actual distance calculations)
        return destinations.sorted { $0.order < $1.order }
    }
    
    func calculateOptimalBudget(for trip: TripModel) -> Double? {
        guard let destinations = trip.destinations, !destinations.isEmpty else { return nil }
        
        // Estimate based on:
        // - Number of destinations
        // - Trip duration
        // - Category
        
        let baseDailyCost: Double
        switch trip.category {
        case "Business":
            baseDailyCost = 300
        case "Adventure":
            baseDailyCost = 150
        case "Family":
            baseDailyCost = 200
        case "Relaxation":
            baseDailyCost = 250
        default:
            baseDailyCost = 180
        }
        
        let destinationMultiplier = 1.0 + (Double(destinations.count - 1) * 0.2)
        let duration = Double(trip.duration)
        
        return baseDailyCost * duration * destinationMultiplier
    }
}



