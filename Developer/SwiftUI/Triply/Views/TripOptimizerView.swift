//
//  TripOptimizerView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct TripOptimizerView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var optimizer = TripOptimizer.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var suggestions: [OptimizationSuggestion] = []
    @State private var optimalBudget: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Optimal Budget Card
                if let optimalBudget = optimalBudget {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            Text("Recommended Budget")
                                .font(.headline)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("AI Suggested")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(settingsManager.formatAmount(optimalBudget))
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            if let currentBudget = trip.budget {
                                VStack(alignment: .trailing) {
                                    Text("Your Budget")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(settingsManager.formatAmount(currentBudget))
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.2), Color.orange.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Suggestions
                if suggestions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("No Optimizations Needed")
                            .font(.headline)
                        Text("Your trip is well planned!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Optimization Suggestions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(suggestions) { suggestion in
                            OptimizationCardView(
                                suggestion: suggestion,
                                settingsManager: settingsManager
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Trip Optimizer")
        .onAppear {
            suggestions = optimizer.optimizeTrip(trip)
            optimalBudget = optimizer.calculateOptimalBudget(for: trip)
        }
    }
}

struct OptimizationCardView: View {
    let suggestion: OptimizationSuggestion
    let settingsManager: SettingsManager
    
    var icon: String {
        switch suggestion.type {
        case .route: return "map.fill"
        case .cost: return "dollarsign.circle.fill"
        case .timing: return "clock.fill"
        case .accommodation: return "bed.double.fill"
        }
    }
    
    var color: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(suggestion.title)
                        .font(.headline)
                    Spacer()
                    if suggestion.priority == .high {
                        Text("HIGH")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(6)
                    }
                }
                
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let savings = suggestion.potentialSavings {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Potential savings: \(settingsManager.formatAmount(savings))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        TripOptimizerView(trip: TripModel(
            name: "Test Trip",
            startDate: Date(),
            endDate: Date()
        ))
        .modelContainer(for: [TripModel.self], inMemory: true)
    }
}



