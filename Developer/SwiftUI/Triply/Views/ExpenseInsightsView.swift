//
//  ExpenseInsightsView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import Charts

struct ExpenseInsightsView: View {
    let trip: TripModel
    @StateObject private var settingsManager = SettingsManager.shared
    
    var expenses: [Expense] {
        trip.expenses?.sorted(by: { $0.date > $1.date }) ?? []
    }
    
    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var averageDailySpend: Double {
        guard trip.duration > 0 else { return 0 }
        return totalSpent / Double(trip.duration)
    }
    
    var expensesByCategory: [String: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var topExpense: Expense? {
        expenses.max(by: { $0.amount < $1.amount })
    }
    
    var spendingTrend: [DailySpending] {
        let calendar = Calendar.current
        var daily: [Date: Double] = [:]
        
        for expense in expenses {
            let day = calendar.startOfDay(for: expense.date)
            daily[day, default: 0] += expense.amount
        }
        
        return daily.map { DailySpending(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Spent",
                        value: settingsManager.formatAmount(totalSpent),
                        icon: "creditcard.fill",
                        color: .red
                    )
                    SummaryCard(
                        title: "Daily Average",
                        value: settingsManager.formatAmount(averageDailySpend),
                        icon: "calendar",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Budget Comparison
                if let budget = trip.budget {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget vs Spending")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        BudgetProgressView(
                            budget: budget,
                            spent: totalSpent,
                            settingsManager: settingsManager
                        )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Category Breakdown
                if !expensesByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spending by Category")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ExpenseCategoryChartView(
                            expensesByCategory: expensesByCategory,
                            settingsManager: settingsManager
                        )
                        .frame(height: 250)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Spending Trend
                if !spendingTrend.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Spending Trend")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        SpendingTrendChartView(
                            spendingTrend: spendingTrend,
                            settingsManager: settingsManager
                        )
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Top Expense
                if let topExpense = topExpense {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Largest Expense")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(topExpense.title)
                                    .font(.headline)
                                Text(topExpense.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(settingsManager.formatAmount(topExpense.amount))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Expense Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DailySpending: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct BudgetProgressView: View {
    let budget: Double
    let spent: Double
    let settingsManager: SettingsManager
    
    var progress: Double {
        min(spent / budget, 1.0)
    }
    
    var remaining: Double {
        max(budget - spent, 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(settingsManager.formatAmount(budget))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(settingsManager.formatAmount(spent))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(progress > 0.9 ? .red : .primary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(progress > 0.9 ? Color.red : Color.green)
                        .frame(width: geometry.size.width * progress, height: 20)
                        .cornerRadius(10)
                }
            }
            .frame(height: 20)
            
            HStack {
                Text("\(Int(progress * 100))% used")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(settingsManager.formatAmount(remaining)) remaining")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(remaining > 0 ? .green : .red)
            }
        }
    }
}

struct ExpenseCategoryChartView: View {
    let expensesByCategory: [String: Double]
    let settingsManager: SettingsManager
    
    var chartData: [(category: String, amount: Double)] {
        expensesByCategory.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
    
    var body: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                BarMark(
                    x: .value("Category", item.category),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(by: .value("Category", item.category))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
            }
        }
    }
}

struct SpendingTrendChartView: View {
    let spendingTrend: [DailySpending]
    let settingsManager: SettingsManager
    
    var body: some View {
        Chart {
            ForEach(spendingTrend) { day in
                LineMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Amount", day.amount)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Amount", day.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}

