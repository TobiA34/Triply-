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
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.05)
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
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                            .accessibilityIdentifier("trip_name")
                            .accessibilityLabel(trip.name)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption.weight(.medium))
                            Text(trip.formattedDateRange)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                        topLeading: 22,
                        bottomLeading: 0,
                        bottomTrailing: 0,
                        topTrailing: 22
                    )
                )
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Stats Row with better spacing
                HStack(spacing: 0) {
                    StatItem(
                        icon: "clock.fill",
                        value: "\(trip.duration)",
                        label: "trips.days".localized,
                        color: .blue
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)
                    
                    StatItem(
                        icon: "mappin.circle.fill",
                        value: "\(trip.destinations?.count ?? 0)",
                        label: "trips.places".localized,
                        color: .green
                    )
                    
                    if let budget = trip.budget {
                        Divider()
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                        
                        StatItem(
                            icon: settingsManager.currencyIconName(filled: true),
                            value: formatBudget(budget),
                            label: "trips.budget".localized,
                            color: .blue
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Color(red: 0.96, green: 0.98, blue: 1.0)
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 0,
                                bottomLeading: 22,
                                bottomTrailing: 22,
                                topTrailing: 0
                            )
                        )
                    )
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 1.0, green: 0.99, blue: 0.98))
                .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 12)
                .shadow(color: Color(red: 0.95, green: 0.5, blue: 0.3).opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
    
    private var gradientColors: [Color] {
        switch trip.category.lowercased() {
        case "business":
            return [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.5, green: 0.65, blue: 1.0)]
        case "relaxation", "vacation", "leisure":
            return [Color(red: 1.0, green: 0.65, blue: 0.45), Color(red: 1.0, green: 0.5, blue: 0.6)]
        case "adventure":
            return [Color(red: 0.25, green: 0.75, blue: 0.55), Color(red: 0.4, green: 0.8, blue: 0.65)]
        case "family":
            return [Color(red: 1.0, green: 0.55, blue: 0.7), Color(red: 0.95, green: 0.5, blue: 0.85)]
        default:
            return [Color(red: 0.95, green: 0.5, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.45)]
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
                    .foregroundColor(Color(red: 0.18, green: 0.16, blue: 0.2))
                
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.42, blue: 0.48))
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
            return "trips.upcoming".localized
        } else if trip.isCurrent {
            return "trips.statusActive".localized
        } else {
            return "trips.statusPast".localized
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
                .font(.caption2.weight(.bold))
            Text("in \(daysUntilTrip)d")
                .font(.caption.weight(.bold))
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
    guard let container = try? ModelContainer(for: TripModel.self, configurations: config) else {
        return AnyView(Text("Preview unavailable"))
    }
    let sampleTrip = TripModel(
        name: "Paris Adventure",
        startDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 22, to: Date()) ?? Date(),
        notes: "Sample trip",
        category: "Adventure",
        budget: 2000.0
    )
    return AnyView(
        EnhancedTripCard(trip: sampleTrip)
            .padding()
            .modelContainer(container)
    )
}





