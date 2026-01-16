//
//  AnalyticsView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var settingsManager = SettingsManager.shared
    @Query private var trips: [TripModel]
    
    var totalBudget: Double {
        trips.compactMap { $0.budget }.reduce(0, +)
    }
    
    var totalExpenses: Double {
        trips.compactMap { $0.expenses?.reduce(0) { $0 + $1.amount } }.reduce(0, +)
    }
    
    var tripsByCategory: [String: Int] {
        Dictionary(grouping: trips, by: { $0.category })
            .mapValues { $0.count }
    }
    
    var expensesByCategory: [String: Double] {
        var categoryExpenses: [String: Double] = [:]
        for trip in trips {
            for expense in trip.expenses ?? [] {
                categoryExpenses[expense.category, default: 0] += expense.amount
            }
        }
        return categoryExpenses
    }
    
    var monthlySpending: [MonthlyData] {
        let calendar = Calendar.current
        var monthly: [String: Double] = [:]
        
        for trip in trips {
            for expense in trip.expenses ?? [] {
                let monthKey = calendar.dateComponents([.year, .month], from: expense.date)
                let monthName = calendar.monthSymbols[monthKey.month! - 1]
                let key = "\(monthName) \(monthKey.year!)"
                monthly[key, default: 0] += expense.amount
            }
        }
        
        return monthly.map { MonthlyData(month: $0.key, amount: $0.value) }
            .sorted { $0.month < $1.month }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                HStack(spacing: 16) {
                    AnalyticsSummaryCard(
                        title: "Total Trips",
                        value: "\(trips.count)",
                        icon: "airplane",
                        color: .blue
                    )
                    AnalyticsSummaryCard(
                        title: "Total Budget",
                        value: settingsManager.formatAmount(totalBudget),
                        icon: "dollarsign.circle",
                        color: .green
                    )
                    AnalyticsSummaryCard(
                        title: "Total Spent",
                        value: settingsManager.formatAmount(totalExpenses),
                        icon: "creditcard",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Budget vs Expenses
                if totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Budget Overview")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        BudgetChartView(
                            budget: totalBudget,
                            spent: totalExpenses,
                            settingsManager: settingsManager
                        )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Trips by Category
                if !tripsByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trips by Category")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        CategoryChartView(data: tripsByCategory)
                            .frame(height: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }
                }
                
                // Expenses by Category
                if !expensesByCategory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expenses by Category")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        AnalyticsExpenseCategoryChartView(
                            data: expensesByCategory,
                            settingsManager: settingsManager
                        )
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                
                // Monthly Spending
                if !monthlySpending.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Spending")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        MonthlySpendingChartView(
                            data: monthlySpending,
                            settingsManager: settingsManager
                        )
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
    }
}

struct AnalyticsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BudgetChartView: View {
    let budget: Double
    let spent: Double
    let settingsManager: SettingsManager
    
    var remaining: Double {
        max(0, budget - spent)
    }
    
    var body: some View {
        VStack(spacing: 16) {
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
                        .foregroundColor(.red)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: min(geometry.size.width, geometry.size.width * CGFloat(spent / budget)), height: 20)
                        .cornerRadius(10)
                    
                    if remaining > 0 {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * CGFloat(remaining / budget), height: 20)
                            .cornerRadius(10)
                            .offset(x: geometry.size.width * CGFloat(spent / budget))
                    }
                }
            }
            .frame(height: 20)
            
            HStack {
                Label("Spent", systemImage: "square.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Spacer()
                Label("Remaining", systemImage: "square.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

struct CategoryChartView: View {
    let data: [String: Int]
    
    var body: some View {
        Chart {
            ForEach(Array(data.keys.sorted()), id: \.self) { category in
                BarMark(
                    x: .value("Category", category),
                    y: .value("Count", data[category] ?? 0)
                )
                .foregroundStyle(by: .value("Category", category))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
    }
}

struct AnalyticsExpenseCategoryChartView: View {
    let data: [String: Double]
    let settingsManager: SettingsManager
    
    var body: some View {
        Chart {
            ForEach(Array(data.keys.sorted()), id: \.self) { category in
                BarMark(
                    x: .value("Category", category),
                    y: .value("Amount", data[category] ?? 0)
                )
                .foregroundStyle(by: .value("Category", category))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(settingsManager.formatAmount(doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct MonthlySpendingChartView: View {
    let data: [MonthlyData]
    let settingsManager: SettingsManager
    
    var body: some View {
        Chart(data) { item in
            LineMark(
                x: .value("Month", item.month),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Month", item.month),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(settingsManager.formatAmount(doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
            .modelContainer(for: [TripModel.self, Expense.self], inMemory: true)
    }
}

