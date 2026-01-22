//
//  ActiveTripWidget.swift
//  Itinero
//
//  Widget showing currently active trip
//

import WidgetKit
import SwiftUI

struct ActiveTripWidget: Widget {
    let kind: String = "ActiveTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveTripProvider()) { entry in
            ActiveTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Active Trip")
        .description("Shows your currently active trip with progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ActiveTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
            date: Date(),
            trip: TripWidgetData(
                id: UUID(),
                name: "European Adventure",
                destination: "Multiple Cities",
                startDate: Date().addingTimeInterval(-86400 * 2),
                endDate: Date().addingTimeInterval(86400 * 5),
                daysUntil: 0,
                isActive: true,
                currentDay: 3,
                totalDays: 7,
                budget: 3000.0,
                totalExpenses: 1200.0,
                category: "Adventure",
                coverImageData: nil
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        let trip = loadActiveTrip()
        completion(TripWidgetEntry(date: Date(), trip: trip))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadActiveTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadActiveTrip() -> TripWidgetData? {
        // Load from SwiftData using WidgetDataLoader
        if let trip = WidgetDataLoader.getActiveTrip() {
            print("✅ Widget: Loaded active trip: \(trip.name)")
            return WidgetDataLoader.convertToWidgetData(trip)
        }
        // No active trip found
        print("⚠️ Widget: No active trip found")
        return nil
    }
}

struct ActiveTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallActiveWidget(trip: entry.trip)
        case .systemMedium:
            MediumActiveWidget(trip: entry.trip)
        default:
            LargeActiveWidget(trip: entry.trip)
        }
    }
}

struct SmallActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(spacing: 8) {
            if let trip = trip, trip.isActive {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(trip.currentDay ?? 0) / CGFloat(trip.totalDays))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(trip.currentDay ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(trip.totalDays - (trip.currentDay ?? 0)) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip, trip.isActive {
                // Day Counter
                VStack {
                    Text("Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trip.currentDay ?? 0)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                    Text("of \(trip.totalDays)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Now")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    
                    Text("\(trip.totalDays - (trip.currentDay ?? 0)) days remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip, trip.isActive {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Trip")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(trip.destination)
                        .font(.headline)
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                }
                
                // Budget (if available)
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
                            .tint(.blue)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing currently active trip
//

import WidgetKit
import SwiftUI

struct ActiveTripWidget: Widget {
    let kind: String = "ActiveTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveTripProvider()) { entry in
            ActiveTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Active Trip")
        .description("Shows your currently active trip with progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ActiveTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
            date: Date(),
            trip: TripWidgetData(
                id: UUID(),
                name: "European Adventure",
                destination: "Multiple Cities",
                startDate: Date().addingTimeInterval(-86400 * 2),
                endDate: Date().addingTimeInterval(86400 * 5),
                daysUntil: 0,
                isActive: true,
                currentDay: 3,
                totalDays: 7,
                budget: 3000.0,
                totalExpenses: 1200.0,
                category: "Adventure",
                coverImageData: nil
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        let trip = loadActiveTrip()
        completion(TripWidgetEntry(date: Date(), trip: trip))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadActiveTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadActiveTrip() -> TripWidgetData? {
        // Load from SwiftData using WidgetDataLoader
        if let trip = WidgetDataLoader.getActiveTrip() {
            print("✅ Widget: Loaded active trip: \(trip.name)")
            return WidgetDataLoader.convertToWidgetData(trip)
        }
        // No active trip found
        print("⚠️ Widget: No active trip found")
        return nil
    }
}

struct ActiveTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallActiveWidget(trip: entry.trip)
        case .systemMedium:
            MediumActiveWidget(trip: entry.trip)
        default:
            LargeActiveWidget(trip: entry.trip)
        }
    }
}

struct SmallActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(spacing: 8) {
            if let trip = trip, trip.isActive {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(trip.currentDay ?? 0) / CGFloat(trip.totalDays))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(trip.currentDay ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(trip.totalDays - (trip.currentDay ?? 0)) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip, trip.isActive {
                // Day Counter
                VStack {
                    Text("Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trip.currentDay ?? 0)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                    Text("of \(trip.totalDays)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Now")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    
                    Text("\(trip.totalDays - (trip.currentDay ?? 0)) days remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip, trip.isActive {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Trip")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(trip.destination)
                        .font(.headline)
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                }
                
                // Budget (if available)
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
                            .tint(.blue)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing currently active trip
//

import WidgetKit
import SwiftUI

struct ActiveTripWidget: Widget {
    let kind: String = "ActiveTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveTripProvider()) { entry in
            ActiveTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Active Trip")
        .description("Shows your currently active trip with progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ActiveTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
            date: Date(),
            trip: TripWidgetData(
                id: UUID(),
                name: "European Adventure",
                destination: "Multiple Cities",
                startDate: Date().addingTimeInterval(-86400 * 2),
                endDate: Date().addingTimeInterval(86400 * 5),
                daysUntil: 0,
                isActive: true,
                currentDay: 3,
                totalDays: 7,
                budget: 3000.0,
                totalExpenses: 1200.0,
                category: "Adventure",
                coverImageData: nil
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        let trip = loadActiveTrip()
        completion(TripWidgetEntry(date: Date(), trip: trip))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadActiveTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadActiveTrip() -> TripWidgetData? {
        // Load from SwiftData using WidgetDataLoader
        if let trip = WidgetDataLoader.getActiveTrip() {
            print("✅ Widget: Loaded active trip: \(trip.name)")
            return WidgetDataLoader.convertToWidgetData(trip)
        }
        // No active trip found
        print("⚠️ Widget: No active trip found")
        return nil
    }
}

struct ActiveTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallActiveWidget(trip: entry.trip)
        case .systemMedium:
            MediumActiveWidget(trip: entry.trip)
        default:
            LargeActiveWidget(trip: entry.trip)
        }
    }
}

struct SmallActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(spacing: 8) {
            if let trip = trip, trip.isActive {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(trip.currentDay ?? 0) / CGFloat(trip.totalDays))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(trip.currentDay ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(trip.totalDays - (trip.currentDay ?? 0)) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip, trip.isActive {
                // Day Counter
                VStack {
                    Text("Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trip.currentDay ?? 0)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                    Text("of \(trip.totalDays)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Now")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    
                    Text("\(trip.totalDays - (trip.currentDay ?? 0)) days remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip, trip.isActive {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Trip")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(trip.destination)
                        .font(.headline)
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                }
                
                // Budget (if available)
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
                            .tint(.blue)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing currently active trip
//

import WidgetKit
import SwiftUI

struct ActiveTripWidget: Widget {
    let kind: String = "ActiveTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ActiveTripProvider()) { entry in
            ActiveTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Active Trip")
        .description("Shows your currently active trip with progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ActiveTripProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
            date: Date(),
            trip: TripWidgetData(
                id: UUID(),
                name: "European Adventure",
                destination: "Multiple Cities",
                startDate: Date().addingTimeInterval(-86400 * 2),
                endDate: Date().addingTimeInterval(86400 * 5),
                daysUntil: 0,
                isActive: true,
                currentDay: 3,
                totalDays: 7,
                budget: 3000.0,
                totalExpenses: 1200.0,
                category: "Adventure",
                coverImageData: nil
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        let trip = loadActiveTrip()
        completion(TripWidgetEntry(date: Date(), trip: trip))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadActiveTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadActiveTrip() -> TripWidgetData? {
        // Load from SwiftData using WidgetDataLoader
        if let trip = WidgetDataLoader.getActiveTrip() {
            print("✅ Widget: Loaded active trip: \(trip.name)")
            return WidgetDataLoader.convertToWidgetData(trip)
        }
        // No active trip found
        print("⚠️ Widget: No active trip found")
        return nil
    }
}

struct ActiveTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallActiveWidget(trip: entry.trip)
        case .systemMedium:
            MediumActiveWidget(trip: entry.trip)
        default:
            LargeActiveWidget(trip: entry.trip)
        }
    }
}

struct SmallActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(spacing: 8) {
            if let trip = trip, trip.isActive {
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(trip.currentDay ?? 0) / CGFloat(trip.totalDays))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(trip.currentDay ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(trip.totalDays - (trip.currentDay ?? 0)) days left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip, trip.isActive {
                // Day Counter
                VStack {
                    Text("Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(trip.currentDay ?? 0)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                    Text("of \(trip.totalDays)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active Now")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    
                    Text("\(trip.totalDays - (trip.currentDay ?? 0)) days remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeActiveWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip, trip.isActive {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Trip")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Destination
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(trip.destination)
                        .font(.headline)
                }
                
                // Progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                }
                
                // Budget (if available)
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
                            .tint(.blue)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

