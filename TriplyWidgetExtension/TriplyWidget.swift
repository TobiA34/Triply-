//
//  ItineroWidget.swift
//  Itinero
//
//  Customizable Home Screen Widgets for Trips
//

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration

struct ItineroWidget: Widget {
    let kind: String = "ItineroWidget"
    
    var body: some WidgetConfiguration {
        // Use StaticConfiguration for now since widget extensions can't access main app's database
        // without App Groups. This will show the most relevant trip automatically.
        StaticConfiguration(kind: kind, provider: TripTimelineProvider()) { entry in
            ItineroWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trip Widget")
        .description("Display your upcoming or active trip on your Home Screen")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry

struct TripWidgetEntry: TimelineEntry {
    let date: Date
    let trip: TripWidgetData?
}

struct TripWidgetData {
    let id: UUID
    let name: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let daysUntil: Int
    let isActive: Bool
    let currentDay: Int?
    let totalDays: Int
    let budget: Double?
    let totalExpenses: Double
    let category: String
    let coverImageData: Data?
}

// MARK: - Timeline Provider

struct TripTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
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
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        // Use placeholder for snapshots to avoid crashes
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        // Safely load trip data
        let trip = loadTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTrip() -> TripWidgetData? {
        // Safely try to load trips from SwiftData
        // Note: Widget extensions can't access main app's database without App Groups
        // This will return empty array, and widget will show "No Trip Selected"
        let trips = WidgetDataLoader.loadTrips()
        
        // If we have trips, find the most relevant one
        guard !trips.isEmpty else {
            return nil
        }
        
        let now = Date()
        
        // First try to find an active trip
        if let activeTrip = trips.first(where: { $0.startDate <= now && $0.endDate >= now }) {
            return WidgetDataLoader.convertToWidgetData(activeTrip)
        }
        
        // Then try to find the next upcoming trip
        if let upcomingTrip = trips.first(where: { $0.startDate > now }) {
            return WidgetDataLoader.convertToWidgetData(upcomingTrip)
        }
        
        // Finally, get the most recent trip
        if let mostRecentTrip = trips.first {
            return WidgetDataLoader.convertToWidgetData(mostRecentTrip)
        }
        
        return nil
    }
}

// MARK: - Widget Entry View

struct ItineroWidgetEntryView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallTripWidget(trip: entry.trip)
            case .systemMedium:
                MediumTripWidget(trip: entry.trip)
            case .systemLarge:
                LargeTripWidget(trip: entry.trip)
            default:
                SmallTripWidget(trip: entry.trip)
            }
        }
    }
}

// MARK: - Small Widget

struct SmallTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        ZStack {
            // Gradient background
            if let trip = trip {
                LinearGradient(
                    colors: gradientColors(for: trip.category),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.15)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                if let trip = trip {
                    // Header with icon and badge
                    HStack(alignment: .top) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: iconForCategory(trip.category))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Status badge with animation
                        if trip.isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Day \(trip.currentDay ?? 0)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.9))
                                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        } else {
                            VStack(spacing: 2) {
                                Text("\(trip.daysUntil)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("days")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
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
                    
                    Spacer()
                    
                    // Trip Name
                    Text(trip.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Destination with icon
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(trip.destination)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Progress or countdown
                    if trip.isActive {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                                .tint(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                            
                            Text("\(trip.currentDay ?? 0) of \(trip.totalDays) days")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Starts \(formatCountdown(trip.daysUntil))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Enhanced Empty State
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
            .padding(14)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatCountdown(_ days: Int) -> String {
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "tomorrow"
        } else if days < 7 {
            return "in \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "in \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = days / 30
            return "in \(months) month\(months == 1 ? "" : "s")"
        }
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business":
            return [Color.blue, Color.purple]
        case "leisure", "vacation":
            return [Color.orange, Color.pink]
        case "adventure":
            return [Color.green, Color.teal]
        default:
            return [Color.blue, Color.cyan]
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

struct MediumTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        ZStack {
            // Gradient background
            if let trip = trip {
                LinearGradient(
                    colors: gradientColors(for: trip.category),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.12)
            }
            
            HStack(spacing: 14) {
                if let trip = trip {
                    // Left: Enhanced Icon and Status
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 70, height: 70)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: iconForCategory(trip.category))
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        if trip.isActive {
                            VStack(spacing: 2) {
                                Text("Day")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("\(trip.currentDay ?? 0)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.green)
                                Text("of \(trip.totalDays)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("\(trip.daysUntil)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(LinearGradient(
                                        colors: gradientColors(for: trip.category),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ))
                                Text("days")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Right: Enhanced Details
                    VStack(alignment: .leading, spacing: 8) {
                        // Trip Name
                        Text(trip.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Destination
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                            Text(trip.destination)
                                .font(.system(size: 13, weight: .medium))
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
                        
                        // Budget with progress
                        if let budget = trip.budget, budget > 0 {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.green)
                                    Text("$\(Int(trip.totalExpenses)) / $\(Int(budget))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(Int((trip.totalExpenses / budget) * 100))%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                
                                ProgressView(value: min(trip.totalExpenses, budget), total: max(budget, 0.1))
                                    .tint(LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .scaleEffect(x: 1, y: 1.3, anchor: .center)
                            }
                            .padding(.top, 2)
                        }
                        
                        // Trip Progress
                        if trip.isActive {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Progress")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                
                            ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                                .tint(LinearGradient(
                                    colors: gradientColors(for: trip.category),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                    .scaleEffect(x: 1, y: 1.3, anchor: .center)
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                } else {
                    // Enhanced Empty State
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 40))
                                .foregroundColor(.blue.opacity(0.6))
                        }
                        
                        VStack(spacing: 6) {
                            Text("No Trip Selected")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("Add a trip to see it here")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business":
            return [Color.blue, Color.purple]
        case "leisure", "vacation":
            return [Color.orange, Color.pink]
        case "adventure":
            return [Color.green, Color.teal]
        default:
            return [Color.blue, Color.cyan]
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

struct LargeTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip {
                // Header
                HStack {
                    Image(systemName: iconForCategory(trip.category))
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(trip.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if trip.isActive {
                        VStack {
                            Text("Day \(trip.currentDay ?? 0)")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("of \(trip.totalDays)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(12)
                    } else {
                        VStack {
                            Text("\(trip.daysUntil)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
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
                if let budget = trip.budget, budget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                            .tint(.blue)
                    }
                }
            } else {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "airplane")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Trip Selected")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Long press this widget and select 'Edit Widget' to choose a trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
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

// MARK: - Widget Bundle
// NOTE: The @main WidgetBundle is in ItineroWidgetExtensionBundle.swift
// This struct is kept for reference but is not used (no @main attribute)
// NOTE: For widgets to appear in widget gallery, they MUST be in a Widget Extension target
// with @main on the WidgetBundle. This bundle is for reference.
// 
// To make widgets work:
// 1. Create Widget Extension target in Xcode (File → New → Target → Widget Extension)
// 2. Move widget files to extension
// 3. Create @main WidgetBundle in extension
// 4. Build extension scheme
// 5. Widgets will appear in widget gallery

// MARK: - Widget Bundle
// NOTE: The @main WidgetBundle is in ItineroWidgetExtensionBundle.swift
// This struct is kept for reference but is not used (no @main attribute)
// NOTE: For widgets to appear in widget gallery, they MUST be in a Widget Extension target
// with @main on the WidgetBundle. This bundle is for reference.
// 
// To make widgets work:
// 1. Create Widget Extension target in Xcode (File → New → Target → Widget Extension)
// 2. Move widget files to extension
// 3. Create @main WidgetBundle in extension
// 4. Build extension scheme
// 5. Widgets will appear in widget gallery

struct ItineroWidgetBundle: WidgetBundle {
    var body: some Widget {
        ItineroWidget()
        UpcomingTripWidget()
        ActiveTripWidget()
        TripStatsWidget()
    }
}