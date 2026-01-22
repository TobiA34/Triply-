//
//  ExpenseChartView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import Charts

struct ExpenseChartView: View {
    let trip: TripModel
    @State private var selectedCategory: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Expense Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if let expenses = trip.expenses, !expenses.isEmpty {
                // Pie Chart
                Chart {
                    ForEach(categoryData, id: \.category) { data in
                        SectorMark(
                            angle: .value("Amount", data.amount),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("Category", data.category))
                        .opacity(selectedCategory == nil || selectedCategory == data.category ? 1.0 : 0.3)
                    }
                }
                .frame(height: 250)
                .chartAngleSelection(value: $selectedCategory)
                .padding()
                
                // Category List
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(categoryData, id: \.category) { data in
                        CategoryRow(data: data, isSelected: selectedCategory == data.category)
                            .onTapGesture {
                                withAnimation {
                                    selectedCategory = selectedCategory == data.category ? nil : data.category
                                    HapticManager.shared.selection()
                                }
                            }
                    }
                }
                .padding(.horizontal)
            } else {
                EmptyExpenseView()
            }
        }
        .padding(.vertical)
    }
    
    private var categoryData: [CategoryData] {
        guard let expenses = trip.expenses else { return [] }
        
        let grouped = Dictionary(grouping: expenses) { $0.category }
        return grouped.map { category, expenses in
            CategoryData(
                category: category,
                amount: expenses.reduce(0) { $0 + $1.amount },
                count: expenses.count,
                color: colorForCategory(category)
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category.lowercased() {
        case "food", "dining", "restaurant":
            return .orange
        case "transportation", "transport":
            return .blue
        case "accommodation", "hotel":
            return .purple
        case "entertainment", "activity":
            return .pink
        case "shopping":
            return .red
        default:
            return .gray
        }
    }
}

struct CategoryData {
    let category: String
    let amount: Double
    let count: Int
    let color: Color
}

struct CategoryRow: View {
    let data: CategoryData
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(data.color)
                .frame(width: 12, height: 12)
            
            Text(data.category)
                .font(.headline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(data.amount))
                    .font(.headline)
                Text("\(data.count) item\(data.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isSelected ? data.color.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? data.color : Color.clear, lineWidth: 2)
        )
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

struct EmptyExpenseView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Expenses Yet")
                .font(.headline)
            Text("Add expenses to see visual breakdown")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 230)
        .padding(.horizontal, 40)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let sampleTrip = TripModel(
        name: "Test Trip",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        notes: "",
        category: "General"
    )
    
    return ExpenseChartView(trip: sampleTrip)
        .modelContainer(container)
}


