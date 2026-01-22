//
//  BudgetInsightsView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct BudgetInsightsView: View {
    @StateObject private var iapManager = IAPManager.shared
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var aiFoundation = AppleAIFoundation.shared
    let trip: TripModel
    
    @State private var insights: String = ""
    @State private var isLoading = true
    
    var totalSpent: Double {
        trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
    }
    
    var budgetRemaining: Double {
        (trip.budget ?? 0) - totalSpent
    }
    
    var budgetPercentage: Double {
        guard let budget = trip.budget, budget > 0 else { return 0 }
        return (totalSpent / budget) * 100
    }
    
    var body: some View {
        if !iapManager.isPro {
            PaywallGateView(
                featureName: "Budget Insights",
                featureDescription: "Get AI-powered budget analysis, spending predictions, and cost-saving suggestions for your trip.",
                icon: "chart.pie.fill",
                iconColor: .teal
            )
            .navigationTitle("Budget Insights")
        } else {
            budgetInsightsContent
        }
    }
    
    private var budgetInsightsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Budget Overview
                VStack(spacing: 16) {
                    Text("Budget Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Budget Card
                    VStack(spacing: 12) {
                        HStack {
                            Text("Total Budget")
                                .font(.headline)
                            Spacer()
                            Text(settingsManager.formatAmount(trip.budget ?? 0))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Spent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(settingsManager.formatAmount(totalSpent))
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Remaining")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(settingsManager.formatAmount(budgetRemaining))
                                .font(.headline)
                                .foregroundColor(budgetRemaining >= 0 ? .green : .red)
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(budgetPercentage > 100 ? Color.red : Color.blue)
                                    .frame(width: min(geometry.size.width * CGFloat(budgetPercentage / 100), geometry.size.width), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("\(String(format: "%.0f", budgetPercentage))% used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                
                // AI Insights
                if isLoading {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Budget Insights")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 8) {
                            LoadingSkeleton()
                                .frame(height: 14)
                            LoadingSkeleton()
                                .frame(height: 14)
                            LoadingSkeleton()
                                .frame(height: 14)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                } else if !insights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Budget Insights")
                                .font(.headline)
                        }
                        
                        Text(insights)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                }
                
                // Expense Breakdown
                if let expenses = trip.expenses, !expenses.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expense Breakdown")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(expenses.grouped(by: { $0.category }).keys.sorted()), id: \.self) { category in
                            let categoryExpenses = expenses.filter { $0.category == category }
                            let categoryTotal = categoryExpenses.reduce(0) { $0 + $1.amount }
                            
                            HStack {
                                Text(category)
                                    .font(.subheadline)
                                Spacer()
                                Text(settingsManager.formatAmount(categoryTotal))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationTitle("Budget Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            await generateInsights()
        }
    }
    
    private func generateInsights() async {
        isLoading = true
        
        var analysisText = "Budget Analysis for \(trip.name):\n\n"
        
        if let budget = trip.budget, budget > 0 {
            analysisText += "Total Budget: \(settingsManager.formatAmount(budget))\n"
            analysisText += "Spent: \(settingsManager.formatAmount(totalSpent))\n"
            analysisText += "Remaining: \(settingsManager.formatAmount(budgetRemaining))\n"
            analysisText += "Usage: \(String(format: "%.0f", budgetPercentage))%\n\n"
            
            if budgetPercentage > 100 {
                analysisText += "⚠️ You've exceeded your budget. Consider reviewing expenses.\n\n"
            } else if budgetPercentage > 80 {
                analysisText += "💡 You're approaching your budget limit. Plan remaining expenses carefully.\n\n"
            } else {
                analysisText += "✅ You're within budget. Good planning!\n\n"
            }
            
            if let expenses = trip.expenses, !expenses.isEmpty {
                let avgExpense = totalSpent / Double(expenses.count)
                let dailySpend = totalSpent / Double(max(trip.duration, 1))
                
                analysisText += "Average expense: \(settingsManager.formatAmount(avgExpense))\n"
                analysisText += "Daily spending: \(settingsManager.formatAmount(dailySpend))\n\n"
                
                if dailySpend > 0 && trip.duration > 0 {
                    let projectedTotal = dailySpend * Double(trip.duration)
                    if projectedTotal > budget {
                        analysisText += "📊 At current spending rate, you may exceed your budget.\n"
                    } else {
                        analysisText += "📊 At current spending rate, you're on track.\n"
                    }
                }
            }
        } else {
            analysisText += "No budget set for this trip. Set a budget to track expenses and get insights."
        }
        
        await MainActor.run {
            insights = analysisText
            isLoading = false
        }
    }
}

extension Sequence {
    func grouped<Key: Hashable>(by keyForValue: (Element) -> Key) -> [Key: [Element]] {
        Dictionary(grouping: self, by: keyForValue)
    }
}

