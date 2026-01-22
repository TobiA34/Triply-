//
//  ActiveTripWidget.swift
//  ItineroWidgetExtension
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
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadActiveTrip() -> TripWidgetData? {
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate <= now && trip.endDate >= now
        }.map { WidgetDataLoader.convertToWidgetData($0) }
    }
}

struct ActiveTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallActiveTripWidget(trip: entry.trip)
            case .systemMedium:
                MediumActiveTripWidget(trip: entry.trip)
            case .systemLarge:
                LargeActiveTripWidget(trip: entry.trip)
            default:
                SmallActiveTripWidget(trip: entry.trip)
            }
        }
    }
}

struct SmallActiveTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let trip = trip {
                HStack {
                    Image(systemName: "airplane.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                    .tint(.green)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumActiveTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Day \(trip.currentDay ?? 0)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.green)
                            Text("of \(trip.totalDays)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(trip.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    
                    if let budget = trip.budget, budget > 0 {
                        HStack {
                            Text("$\(Int(trip.totalExpenses)) / $\(Int(budget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Start a trip to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeActiveTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let trip = trip {
                HStack {
                    Image(systemName: "airplane.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text(trip.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(trip.destination)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Day \(trip.currentDay ?? 0)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("of \(trip.totalDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trip Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ProgressView(value: Double(min(trip.currentDay ?? 0, trip.totalDays)), total: Double(max(trip.totalDays, 1)))
                        .tint(.green)
                    Text("\(Int((Double(trip.currentDay ?? 0) / Double(trip.totalDays)) * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let budget = trip.budget, budget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
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
                    Image(systemName: "airplane")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Active Trip")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Start a trip to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

