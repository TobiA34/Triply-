//
//  UpcomingTripWidget.swift
//  ItineroWidgetExtension
//
//  Widget showing the next upcoming trip
//

import WidgetKit
import SwiftUI

struct UpcomingTripWidget: Widget {
    let kind: String = "UpcomingTripWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingTripProvider()) { entry in
            UpcomingTripWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Upcoming Trip")
        .description("Shows your next upcoming trip with countdown")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct UpcomingTripProvider: TimelineProvider {
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
        let trip = loadUpcomingTrip()
        completion(TripWidgetEntry(date: Date(), trip: trip))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let trip = loadUpcomingTrip()
        let entry = TripWidgetEntry(date: Date(), trip: trip)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadUpcomingTrip() -> TripWidgetData? {
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        return trips.first { trip in
            trip.startDate > now
        }.map { WidgetDataLoader.convertToWidgetData($0) }
    }
}

struct UpcomingTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallUpcomingTripWidget(trip: entry.trip)
            case .systemMedium:
                MediumUpcomingTripWidget(trip: entry.trip)
            default:
                SmallUpcomingTripWidget(trip: entry.trip)
            }
        }
    }
}

struct SmallUpcomingTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let trip = trip {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Spacer()
                    Text("\(trip.daysUntil)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(trip.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No Upcoming Trip")
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

struct MediumUpcomingTripWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(trip.daysUntil)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.blue)
                            Text("days")
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
                    
                    if let budget = trip.budget, budget > 0 {
                        HStack {
                            Text("Budget: $\(Int(trip.totalExpenses)) / $\(Int(budget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Upcoming Trip")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add a trip to see it here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

