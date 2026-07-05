//
//  TripOptimizer.swift
//  Itinero
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
                    title: "tripOptimizer.optimize.route".localized,
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
                    title: "tripOptimizer.budget.exceeded".localized,
                    description: "You've exceeded your budget by \(String(format: "%.0f", abs(remaining)))",
                    potentialSavings: abs(remaining),
                    priority: .high
                ))
            } else if remaining < budget * 0.1 {
                suggestions.append(OptimizationSuggestion(
                    type: .cost,
                    title: "tripOptimizer.budget.warning".localized,
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
                    title: "tripOptimizer.high.spending.category".localized,
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
                title: "tripOptimizer.long.trip.duration".localized,
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
                    title: "tripOptimizer.missing.accommodation".localized,
                    description: "No accommodation expenses recorded. Consider booking in advance for better rates.",
                    potentialSavings: nil,
                    priority: .medium
                ))
            }
        }
        
        return suggestions.sorted { $0.priority == .high && $1.priority != .high }
    }
    
    func optimizeRoute(destinations: [DestinationModel]) -> [DestinationModel] {
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
    
    // MARK: - Automated Itinerary Generation
    
    /// Draft of an itinerary activity (no SwiftData). Caller creates ItineraryItem and inserts.
    struct ItineraryDraft {
        let day: Int
        let date: Date
        let title: String
        let details: String
        let time: String
        let location: String
        let order: Int
    }
    
    /// Generates a day-by-day itinerary from trip dates and destinations. Returns drafts to be turned into ItineraryItem by the caller.
    func generateAutomatedItinerary(for trip: TripModel) -> [ItineraryDraft] {
        let calendar = Calendar.current
        let duration = max(1, trip.duration)
        let start = trip.startDate
        var drafts: [ItineraryDraft] = []
        let destinations = trip.destinations?.sorted(by: { $0.order < $1.order }) ?? []
        
        for dayOffset in 0..<duration {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }
            let day = dayOffset + 1
            
            if destinations.isEmpty {
                drafts.append(ItineraryDraft(
                    day: day,
                    date: dayDate,
                    title: "tripOptimizer.day.day.free.day".localized,
                    details: "Add activities for your trip",
                    time: "09:00",
                    location: "",
                    order: 0
                ))
                continue
            }
            
            let destIndex = dayOffset % destinations.count
            let dest = destinations[destIndex]
            let isFirstDay = dayOffset == 0
            let isLastDay = dayOffset == duration - 1
            
            var order = 0
            if isFirstDay {
                drafts.append(ItineraryDraft(
                    day: day,
                    date: dayDate,
                    title: "tripOptimizer.arrive.destname".localized,
                    details: dest.notes.isEmpty ? "Explore \(dest.name)" : dest.notes,
                    time: "10:00",
                    location: dest.address.isEmpty ? dest.name : dest.address,
                    order: order
                ))
                order += 1
            }
            
            drafts.append(ItineraryDraft(
                day: day,
                date: dayDate,
                title: "tripOptimizer.explore.destname".localized,
                details: dest.notes.isEmpty ? "Activities and sights at \(dest.name)" : dest.notes,
                time: "11:00",
                location: dest.address.isEmpty ? dest.name : dest.address,
                order: order
            ))
            order += 1
            
            if destinations.count > 1 && !isLastDay {
                let nextIndex = (dayOffset + 1) % destinations.count
                let nextDest = destinations[nextIndex]
                drafts.append(ItineraryDraft(
                    day: day,
                    date: dayDate,
                    title: "tripOptimizer.travel.to.nextdestname".localized,
                    details: "Head to next destination",
                    time: "17:00",
                    location: nextDest.name,
                    order: order
                ))
            }
        }
        
        return drafts
    }
}



