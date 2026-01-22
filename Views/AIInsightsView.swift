//
//  AIInsightsView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct AIInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var aiFoundation = AppleAIFoundation.shared
    @StateObject private var settingsManager = SettingsManager.shared
    let trip: TripModel
    @State private var insights: [AIInsight] = []
    @State private var isGenerating = false
    @State private var selectedInsight: AIInsight?
    @State private var navigationTarget: NavigationTarget?
    
    enum NavigationTarget {
        case expenses
        case itinerary
        case packing
        case weather
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Animated Header
                AIHeaderView(trip: trip)
                    .padding(.top)
                
                if isGenerating {
                    GeneratingView()
                } else if !insights.isEmpty {
                    // Insights Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight, isSelected: selectedInsight?.id == insight.id)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedInsight = selectedInsight?.id == insight.id ? nil : insight
                                    }
                                    HapticManager.shared.impact(.light)
                                }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected Insight Detail
                    if let selected = selectedInsight {
                        InsightDetailView(
                            insight: selected,
                            trip: trip,
                            onNavigate: { target in
                                navigationTarget = target
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else {
                    EmptyInsightsView()
                }
            }
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Load settings asynchronously (non-blocking)
            Task {
                settingsManager.loadSettings(from: modelContext)
            }
            generateInsights()
        }
    }
    
    private func generateInsights() {
        isGenerating = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            let generated = createInsights(for: trip)
            await MainActor.run {
                insights = generated
                isGenerating = false
            }
        }
    }
    
    private func createInsights(for trip: TripModel) -> [AIInsight] {
        var insights: [AIInsight] = []
        
        // Budget Insight
        if let budget = trip.budget {
            let spent = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
            let percentage = (spent / budget) * 100
            insights.append(AIInsight(
                type: .budget,
                title: "Budget Health",
                value: "\(Int(percentage))%",
                icon: percentage > 80 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                color: percentage > 80 ? .red : .green,
                description: percentage > 80 ? "You're approaching your budget limit" : "You're on track with your budget"
            ))
        }
        
        // Duration Insight
        let days = trip.duration
        insights.append(AIInsight(
            type: .duration,
            title: "Trip Duration",
            value: "\(days) days",
            icon: "calendar",
            color: .blue,
            description: days > 7 ? "Extended trip - plan for rest days" : "Perfect length for exploration"
        ))
        
        // Destinations Insight
        let destinationCount = trip.destinations?.count ?? 0
        insights.append(AIInsight(
            type: .destinations,
            title: "Destinations",
            value: "\(destinationCount)",
            icon: "mappin.circle.fill",
            color: .purple,
            description: destinationCount > 0 ? "Great planning!" : "Add destinations for better insights"
        ))
        
        // Expenses Insight
        let expenseCount = trip.expenses?.count ?? 0
        insights.append(AIInsight(
            type: .expenses,
            title: "Expenses",
            value: "\(expenseCount)",
            icon: "creditcard.fill",
            color: .orange,
            description: expenseCount > 0 ? "Keep tracking!" : "Start logging expenses"
        ))
        
        // Weather Insight
        if trip.isUpcoming {
            insights.append(AIInsight(
                type: .weather,
                title: "Weather Check",
                value: "Soon",
                icon: "cloud.sun.fill",
                color: .cyan,
                description: "Check weather forecast before departure"
            ))
        }
        
        // Packing Insight
        let packingCount = trip.packingList?.count ?? 0
        insights.append(AIInsight(
            type: .packing,
            title: "Packing List",
            value: "\(packingCount) items",
            icon: "suitcase.fill",
            color: .indigo,
            description: packingCount > 0 ? "Well prepared!" : "Create your packing list"
        ))
        
        return insights
    }
}

struct AIInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let value: String
    let icon: String
    let color: Color
    let description: String
    
    enum InsightType {
        case budget, duration, destinations, expenses, weather, packing
    }
}

struct AIHeaderView: View {
    let trip: TripModel
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            Text("AI Insights")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Smart analysis for: \(trip.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct GeneratingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundColor(.purple)
            }
            
            Text("Analyzing your trip...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

struct InsightCard: View {
    let insight: AIInsight
    let isSelected: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(insight.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)
                    .symbolEffect(.bounce, value: isSelected)
            }
            
            Text(insight.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(insight.color)
            
            Text(insight.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: isSelected ? insight.color.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 10 : 5, x: 0, y: isSelected ? 5 : 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? insight.color : Color.clear, lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct InsightDetailView: View {
    let insight: AIInsight
    let trip: TripModel
    let onNavigate: (AIInsightsView.NavigationTarget) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.title)
                    .foregroundColor(insight.color)
                Text(insight.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Action button
            Button {
                HapticManager.shared.impact(.medium)
                handleNavigation()
            } label: {
                HStack {
                    Text(navigationButtonText)
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(insight.color)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(insight.color.opacity(0.1))
        )
        .padding(.horizontal)
    }
    
    private var navigationButtonText: String {
        switch insight.type {
        case .budget, .expenses:
            return "View Expenses"
        case .packing:
            return "View Packing List"
        case .weather:
            return "View Weather"
        case .duration, .destinations:
            return "View Itinerary"
        }
    }
    
    private func handleNavigation() {
        switch insight.type {
        case .budget, .expenses:
            onNavigate(.expenses)
        case .packing:
            onNavigate(.packing)
        case .weather:
            onNavigate(.weather)
        case .duration, .destinations:
            onNavigate(.itinerary)
        }
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("No Insights Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("AI is analyzing your trip data to provide personalized insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

