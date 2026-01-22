//
//  AIExpenseInsightsCard.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct AIExpenseInsightsCard: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var aiFoundation = AppleAIFoundation.shared
    @StateObject private var settingsManager = SettingsManager.shared
    let trip: TripModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .symbolEffect(.pulse, options: .repeating)
                Text("AI Expense Insights")
                    .font(.headline)
                Spacer()
            }
            
            if let budget = trip.budget, budget > 0 {
                let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
                let remaining = budget - totalExpenses
                let percentage = (totalExpenses / budget) * 100
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget Usage")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(percentage))%")
                            .font(.headline)
                            .foregroundColor(percentage > 80 ? .red : .green)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: percentage > 80 ? [Color.red, Color.orange] : [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(percentage / 100, 1.0), height: 12)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: percentage)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("Spent: \(settingsManager.formatAmount(totalExpenses))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Remaining: \(settingsManager.formatAmount(remaining))")
                            .font(.caption)
                            .foregroundColor(remaining > 0 ? .green : .red)
                    }
                }
                
                // AI Recommendation
                if percentage > 80 {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("AI Tip: You've used \(Int(percentage))% of your budget. Consider reviewing expenses.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                    Text("AI Tip: Set a budget to get personalized spending insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .padding(.horizontal)
        .onAppear {
            // Load settings asynchronously (non-blocking)
            Task {
                settingsManager.loadSettings(from: modelContext)
            }
        }
    }
}

