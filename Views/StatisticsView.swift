//
//  StatisticsView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct StatisticsView: View {
    let trips: [TripModel]
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsManager = SettingsManager.shared
    
    var totalTrips: Int { trips.count }
    var upcomingTrips: Int { trips.filter { $0.isUpcoming }.count }
    var pastTrips: Int { trips.filter { $0.isPast }.count }
    var currentTrips: Int { trips.filter { $0.isCurrent }.count }
    var totalDays: Int { trips.reduce(0) { $0 + $1.duration } }
    var totalBudget: Double { trips.compactMap { $0.budget }.reduce(0, +) }
    
    var categoryDistribution: [String: Int] {
        Dictionary(grouping: trips, by: { $0.category })
            .mapValues { $0.count }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    HStack(spacing: 16) {
                        StatCardView(
                            title: "trips.totalTrips".localized,
                            value: "\(totalTrips)",
                            icon: "airplane",
                            color: .blue
                        )
                        StatCardView(
                            title: "statisticsView.total.days".localized,
                            value: "\(totalDays)",
                            icon: "calendar",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        StatCardView(
                            title: "trips.upcoming".localized,
                            value: "\(upcomingTrips)",
                            icon: "clock",
                            color: .orange
                        )
                        StatCardView(
                            title: "trips.statusPast".localized,
                            value: "\(pastTrips)",
                            icon: "checkmark.circle",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Budget Summary
                    if totalBudget > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("statisticsView.budget.summary".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("trips.totalBudgetLabel".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(settingsManager.formatAmount(totalBudget))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                Spacer()
                                Image(systemName: settingsManager.currencyIconName())
                                    .font(.system(size: 40))
                                    .foregroundColor(.green.opacity(0.3))
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Category Distribution
                    if !categoryDistribution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("analytics.tripsByCategory".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ForEach(Array(categoryDistribution.keys.sorted()), id: \.self) { category in
                                HStack {
                                    CategoryBadge(category: category)
                                    Spacer()
                                    Text("statisticsView.categorydistributioncategory.0".localized)
                                        .font(.headline)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("statistics.title".localized)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Settings are loaded globally via SettingsManager.shared
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    StatisticsView(trips: [])
}

