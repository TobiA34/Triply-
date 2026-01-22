//
//  EnhancedTripCard.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct EnhancedTripCard: View {
    let trip: TripModel
    @State private var isPressed = false
    private let settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with enhanced gradient
            ZStack {
                // Background gradient with overlay
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    // Subtle pattern overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        CategoryBadge(category: trip.category)
                        Spacer()
                        HStack(spacing: 8) {
                            if trip.isUpcoming {
                                CountdownBadge(trip: trip)
                            }
                            StatusIndicator(trip: trip)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13, weight: .medium))
                            Text(trip.formattedDateRange)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    }
                }
                .padding(20)
            }
            .frame(height: 140)
            .clipShape(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 20,
                        bottomLeading: 0,
                        bottomTrailing: 0,
                        topTrailing: 20
                    )
                )
            )
            
            // Content section with improved design
            VStack(alignment: .leading, spacing: 16) {
                // Stats Row with better spacing
                HStack(spacing: 0) {
                    StatItem(
                        icon: "clock.fill",
                        value: "\(trip.duration)",
                        label: "days",
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)
                    
                    StatItem(
                        icon: "mappin.circle.fill",
                        value: "\(trip.destinations?.count ?? 0)",
                        label: "places",
                        color: .green
                    )
                    
                    if let budget = trip.budget {
                        Divider()
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                        
                        StatItem(
                            icon: "dollarsign.circle.fill",
                            value: formatBudget(budget),
                            label: "budget",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Color(.systemBackground)
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 0,
                                bottomLeading: 20,
                                bottomTrailing: 20,
                                topTrailing: 0
                            )
                        )
                    )
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 5,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
    private var gradientColors: [Color] {
        switch trip.category.lowercased() {
        case "business":
            return [Color(red: 0.2, green: 0.4, blue: 0.9), Color(red: 0.1, green: 0.3, blue: 0.8)]
        case "vacation", "leisure":
            return [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 1.0, green: 0.3, blue: 0.5)]
        case "adventure":
            return [Color(red: 0.2, green: 0.7, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.7)]
        default:
            return [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.9)]
        }
    }
    
    private func formatBudget(_ amount: Double) -> String {
        return settingsManager.formatAmount(amount)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusIndicator: View {
    let trip: TripModel
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.5), radius: 3, x: 0, y: 1)
            Text(statusText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.25))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    private var statusColor: Color {
        if trip.isUpcoming {
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        } else if trip.isCurrent {
            return Color(red: 0.2, green: 0.8, blue: 0.4)
        } else {
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }
    
    private var statusText: String {
        if trip.isUpcoming {
            return "Upcoming"
        } else if trip.isCurrent {
            return "Active"
        } else {
            return "Past"
        }
    }
}

struct CountdownBadge: View {
    let trip: TripModel
    
    var daysUntilTrip: Int {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
        return max(0, days)
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock.fill")
                .font(.system(size: 10, weight: .bold))
            Text("\(daysUntilTrip)d")
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.5, blue: 0.2),
                            Color(red: 1.0, green: 0.3, blue: 0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.4), radius: 6, x: 0, y: 3)
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let sampleTrip = TripModel(
        name: "Paris Adventure",
        startDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 22, to: Date()) ?? Date(),
        notes: "Sample trip",
        category: "Adventure",
        budget: 2000.0
    )
    
    EnhancedTripCard(trip: sampleTrip)
        .padding()
        .modelContainer(container)
}





