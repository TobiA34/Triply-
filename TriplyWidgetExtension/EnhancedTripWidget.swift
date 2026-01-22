//
//  EnhancedTripWidget.swift
//  ItineroWidgetExtension
//
//  Enhanced widget with interactive features, animations, and deep linking
//

import WidgetKit
import SwiftUI
import AppIntents

struct EnhancedTripWidget: Widget {
    let kind: String = "EnhancedTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnhancedTripProvider()) { entry in
            EnhancedTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Enhanced Trip Widget")
        .description("Interactive trip widget with deep linking and animations")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Intent (iOS 17+)

@available(iOS 17.0, *)
struct TripWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Trip Widget"
    static var description = IntentDescription("Configure your trip widget")
    
    @Parameter(title: "Show Countdown", default: true)
    var showCountdown: Bool
    
    @Parameter(title: "Show Budget", default: true)
    var showBudget: Bool
    
    @Parameter(title: "Widget Style", default: .modern)
    var style: WidgetStyle
    
    enum WidgetStyle: String, AppEnum {
        case modern
        case classic
        case minimal
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
        static var caseDisplayRepresentations: [WidgetStyle: DisplayRepresentation] = [
            .modern: "Modern",
            .classic: "Classic",
            .minimal: "Minimal"
        ]
    }
}

// MARK: - Timeline Provider

struct EnhancedTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> EnhancedTripEntry {
        EnhancedTripEntry(
            date: Date(),
            trip: TripWidgetData(
                id: UUID(),
                name: "Summer Vacation",
                destination: "Paris, France",
                startDate: Date().addingTimeInterval(86400 * 5),
                endDate: Date().addingTimeInterval(86400 * 12),
                daysUntil: 5,
                isActive: false,
                currentDay: nil,
                totalDays: 7,
                budget: 5000.0,
                totalExpenses: 1200.0,
                category: "Leisure",
                coverImageData: nil
            ),
            showCountdown: true,
            showBudget: true,
            style: .modern
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (EnhancedTripEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<EnhancedTripEntry>) -> Void) {
        let now = Date()
        
        // Load trip data
        let trips = WidgetDataLoader.loadTrips()
        let upcomingTrip = WidgetDataLoader.getUpcomingTrip()
        let activeTrip = WidgetDataLoader.getActiveTrip()
        
        let trip = activeTrip ?? upcomingTrip
        let tripData = trip != nil ? WidgetDataLoader.convertToWidgetData(trip!) : nil
        
        // Default configuration
        let entry = EnhancedTripEntry(
            date: now,
            trip: tripData,
            showCountdown: true,
            showBudget: true,
            style: .modern
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct EnhancedTripEntry: TimelineEntry {
    let date: Date
    let trip: TripWidgetData?
    let showCountdown: Bool
    let showBudget: Bool
    let style: TripWidgetIntent.WidgetStyle
}

// MARK: - Widget View

struct EnhancedTripWidgetView: View {
    var entry: EnhancedTripEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                EnhancedSmallWidget(entry: entry)
            case .systemMedium:
                EnhancedMediumWidget(entry: entry)
            case .systemLarge:
                EnhancedLargeWidget(entry: entry)
            default:
                EnhancedSmallWidget(entry: entry)
            }
        }
        .widgetURL(entry.trip != nil ? URL(string: "itinero://trip/\(entry.trip!.id.uuidString)") : nil)
    }
}

// MARK: - Small Widget

struct EnhancedSmallWidget: View {
    let entry: EnhancedTripEntry
    
    var body: some View {
        ZStack {
            // Animated gradient background
            if let trip = entry.trip {
                AnimatedGradient(colors: gradientColors(for: trip.category))
                    .opacity(0.2)
            }
            
            VStack(spacing: 12) {
                if let trip = entry.trip {
                    // Header with icon
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: iconForCategory(trip.category))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Animated countdown badge
                        if entry.showCountdown {
                            CountdownBadge(days: trip.daysUntil, isActive: trip.isActive, currentDay: trip.currentDay)
                        }
                    }
                    
                    Spacer()
                    
                    // Trip name with animation
                    Text(trip.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Destination
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(trip.destination)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Budget progress (if enabled)
                    if entry.showBudget, let budget = trip.budget, budget > 0 {
                        BudgetProgressBar(spent: trip.totalExpenses, budget: budget)
                    }
                } else {
                    EmptyStateView()
                }
            }
            .padding(14)
        }
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business": return [Color.blue, Color.purple]
        case "leisure", "vacation": return [Color.orange, Color.pink]
        case "adventure": return [Color.green, Color.teal]
        default: return [Color.blue, Color.cyan]
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "business": return "briefcase.fill"
        case "leisure", "vacation": return "beach.umbrella.fill"
        case "adventure": return "mountain.2.fill"
        default: return "airplane"
        }
    }
}

// MARK: - Medium Widget

struct EnhancedMediumWidget: View {
    let entry: EnhancedTripEntry
    
    var body: some View {
        HStack(spacing: 16) {
            if let trip = entry.trip {
                // Left: Large icon and countdown
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                colors: gradientColors(for: trip.category),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: iconForCategory(trip.category))
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if entry.showCountdown {
                        if trip.isActive {
                            VStack(spacing: 2) {
                                Text("Day")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(trip.currentDay ?? 0)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                                Text("of \(trip.totalDays)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("\(trip.daysUntil)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(LinearGradient(
                                        colors: gradientColors(for: trip.category),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                Text("days")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Right: Details
                VStack(alignment: .leading, spacing: 10) {
                    Text(trip.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(LinearGradient(
                                colors: gradientColors(for: trip.category),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                        Text(trip.destination)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Dates
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(formatDateRange(trip.startDate, trip.endDate))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    // Budget (if enabled)
                    if entry.showBudget, let budget = trip.budget, budget > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                                Text("$\(Int(trip.totalExpenses)) / $\(Int(budget))")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(Int((trip.totalExpenses / budget) * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            ProgressView(value: min(trip.totalExpenses, budget), total: max(budget, 0.1))
                                .tint(LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .scaleEffect(x: 1, y: 1.4, anchor: .center)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
            } else {
                EmptyStateView()
            }
        }
        .padding(16)
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business": return [Color.blue, Color.purple]
        case "leisure", "vacation": return [Color.orange, Color.pink]
        case "adventure": return [Color.green, Color.teal]
        default: return [Color.blue, Color.cyan]
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "business": return "briefcase.fill"
        case "leisure", "vacation": return "beach.umbrella.fill"
        case "adventure": return "mountain.2.fill"
        default: return "airplane"
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Large Widget

struct EnhancedLargeWidget: View {
    let entry: EnhancedTripEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let trip = entry.trip {
                // Header
                HStack {
                    Image(systemName: iconForCategory(trip.category))
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: gradientColors(for: trip.category),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.2)
                        )
                        .cornerRadius(16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(trip.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if entry.showCountdown {
                        CountdownBadge(days: trip.daysUntil, isActive: trip.isActive, currentDay: trip.currentDay)
                    }
                }
                
                Divider()
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                    Text(trip.destination)
                        .font(.headline)
                }
                
                // Dates
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(formatDateRange(trip.startDate, trip.endDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Budget
                if entry.showBudget, let budget = trip.budget, budget > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(Int(trip.totalExpenses)) / $\(Int(budget))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: min(trip.totalExpenses, budget), total: max(budget, 0.1))
                            .tint(.green)
                    }
                }
                
                // Progress
                if trip.isActive {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                            .tint(.blue)
                    }
                }
            } else {
                EmptyStateView()
            }
        }
        .padding()
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business": return [Color.blue, Color.purple]
        case "leisure", "vacation": return [Color.orange, Color.pink]
        case "adventure": return [Color.green, Color.teal]
        default: return [Color.blue, Color.cyan]
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "business": return "briefcase.fill"
        case "leisure", "vacation": return "beach.umbrella.fill"
        case "adventure": return "mountain.2.fill"
        default: return "airplane"
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Supporting Views

struct CountdownBadge: View {
    let days: Int
    let isActive: Bool
    let currentDay: Int?
    
    var body: some View {
        if isActive {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Day \(currentDay ?? 0)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.9))
                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        } else {
            VStack(spacing: 2) {
                Text("\(days)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("days")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct BudgetProgressBar: View {
    let spent: Double
    let budget: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("$\(Int(spent))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("$\(Int(budget))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(spent, budget), total: max(budget, 0.1))
                .tint(LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}

struct AnimatedGradient: View {
    let colors: [Color]
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "airplane.departure")
                    .font(.system(size: 28))
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            VStack(spacing: 4) {
                Text("No Trip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Add a trip to get started")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

