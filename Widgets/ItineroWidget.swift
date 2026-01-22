//
//  ItineroWidget.swift
//  Itinero
//
//  Customizable Home Screen Widgets for Trips
//

import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Widget Configuration

@available(iOS 17.0, *)
struct ItineroWidget: Widget {
    let kind: String = "ItineroWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TripSelectionIntent.self, provider: TripAppIntentTimelineProvider()) { entry in
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

// MARK: - App Intent Timeline Provider (iOS 17+)

@available(iOS 17.0, *)
struct TripAppIntentTimelineProvider: AppIntentTimelineProvider {
    typealias Intent = TripSelectionIntent
    typealias Entry = TripWidgetEntry
    
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
    
    func snapshot(for configuration: TripSelectionIntent, in context: Context) async -> TripWidgetEntry {
        let trip = loadTrip(from: configuration)
        return TripWidgetEntry(date: Date(), trip: trip)
    }
    
    func timeline(for configuration: TripSelectionIntent, in context: Context) async -> Timeline<TripWidgetEntry> {
        let trip = loadTrip(from: configuration)
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadTrip(from configuration: TripSelectionIntent) -> TripWidgetData? {
        // If a trip is selected in the intent, use it
        if let selectedTrip = configuration.trip,
           let tripModel = WidgetDataLoader.getTrip(id: selectedTrip.id) {
            return WidgetDataLoader.convertToWidgetData(tripModel)
        }
        
        // Otherwise, load the most recent upcoming or active trip
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // First, try to get an active trip
        if let activeTrip = trips.first(where: { $0.startDate <= now && $0.endDate >= now }) {
            return WidgetDataLoader.convertToWidgetData(activeTrip)
        }
        
        // Then, try to get the next upcoming trip
        if let upcomingTrip = trips.first(where: { $0.startDate > now }) {
            return WidgetDataLoader.convertToWidgetData(upcomingTrip)
        }
        
        // Finally, get the most recent trip (even if past)
        if let mostRecentTrip = trips.first {
            return WidgetDataLoader.convertToWidgetData(mostRecentTrip)
        }
        
        return nil
    }
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
        let trip = loadTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadTrip() -> TripWidgetData? {
        // Load the most recent upcoming or active trip
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // First, try to get an active trip
        if let activeTrip = trips.first(where: { $0.startDate <= now && $0.endDate >= now }) {
            return WidgetDataLoader.convertToWidgetData(activeTrip)
        }
        
        // Then, try to get the next upcoming trip
        if let upcomingTrip = trips.first(where: { $0.startDate > now }) {
            return WidgetDataLoader.convertToWidgetData(upcomingTrip)
        }
        
        // Finally, get the most recent trip (even if past)
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
        VStack(alignment: .leading, spacing: 8) {
            if let trip = trip {
                // Header
            HStack {
                    Image(systemName: iconForCategory(trip.category))
                        .font(.title2)
                    .foregroundColor(.blue)
                    Spacer()
                    if trip.isActive {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    } else {
                        Text("\(trip.daysUntil)d")
                    .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                
                // Trip Name
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                // Destination
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Progress or Days
                if trip.isActive {
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.blue)
                } else {
                    Text("Starts in \(trip.daysUntil) day\(trip.daysUntil == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Empty State
                VStack(spacing: 8) {
                    Image(systemName: "airplane")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Trip Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
}

// MARK: - Medium Widget

struct MediumTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip {
                // Left: Icon and Status
                VStack(spacing: 8) {
                    Image(systemName: iconForCategory(trip.category))
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    
                    if trip.isActive {
                        Text("Day \(trip.currentDay ?? 0)/\(trip.totalDays)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    } else {
                        Text("\(trip.daysUntil)d")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Right: Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(trip.name)
                .font(.headline)
                        .fontWeight(.bold)
                .lineLimit(1)
            
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trip.destination)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDateRange(trip.startDate, trip.endDate))
                    .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let budget = trip.budget, budget > 0 {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("$\(Int(trip.totalExpenses))/\(Int(budget))")
                                .font(.caption)
            .foregroundColor(.secondary)
                        }
                    }
                    
                    if trip.isActive {
                        ProgressView(value: Double(trip.currentDay ?? 0), total: Double(trip.totalDays))
                            .tint(.blue)
                    }
                    
                    // Interactive buttons (iOS 17+)
                    if #available(iOS 17.0, *) {
                        HStack(spacing: 8) {
                            Button(intent: {
                                var action = OpenTripAction()
                                action.tripId = trip.id.uuidString
                                return action
                            }()) {
                                Label("Open", systemImage: "arrow.right.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            
                            Button(intent: {
                                var action = ViewItineraryAction()
                                action.tripId = trip.id.uuidString
                                return action
                            }()) {
                                Label("Itinerary", systemImage: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .padding(.top, 4)
                    }
                }
            
            Spacer()
            } else {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Trip Selected")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Select a trip in widget settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
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
                        ProgressView(value: Double(trip.currentDay ?? 0), total: Double(trip.totalDays))
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
    }
}
