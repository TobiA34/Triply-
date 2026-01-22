//
//  UpcomingTripWidget.swift
//  Itinero
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
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadUpcomingTrip() -> TripWidgetData? {
        // Load from SwiftData using WidgetDataLoader
        if let trip = WidgetDataLoader.getUpcomingTrip() {
            print("✅ Widget: Loaded upcoming trip: \(trip.name)")
            return WidgetDataLoader.convertToWidgetData(trip)
        }
        // No upcoming trip found
        print("⚠️ Widget: No upcoming trip found")
        return nil
    }
}

struct UpcomingTripWidgetView: View {
    var entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemSmall {
            SmallUpcomingWidget(trip: entry.trip)
        } else {
            MediumUpcomingWidget(trip: entry.trip)
        }
    }
}

struct SmallUpcomingWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        VStack(spacing: 8) {
            if let trip = trip {
                // Countdown Circle
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(trip.daysUntil, 30)) / 30.0)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(trip.daysUntil)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("days")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(trip.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(trip.destination)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No Upcoming Trip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumUpcomingWidget: View {
    let trip: TripWidgetData?
    
    var body: some View {
        HStack(spacing: 12) {
            if let trip = trip {
                // Countdown
                VStack {
                    Text("\(trip.daysUntil)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)
                    Text("days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 100)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Upcoming")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(trip.destination)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(trip.startDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Upcoming Trip")
                        .font(.headline)
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
