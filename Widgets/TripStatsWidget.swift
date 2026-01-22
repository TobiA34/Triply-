//
//  TripStatsWidget.swift
//  Itinero
//
//  Widget showing trip statistics
//

import WidgetKit
import SwiftUI

struct TripStatsWidget: Widget {
    let kind: String = "TripStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripStatsProvider()) { entry in
            TripStatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trip Statistics")
        .description("Shows your trip statistics and overview")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TripStatsData {
    let totalTrips: Int
    let upcomingTrips: Int
    let activeTrips: Int
    let totalSpent: Double
    let totalBudget: Double
}

struct TripStatsEntry: TimelineEntry {
    let date: Date
    let stats: TripStatsData?
}

struct TripStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripStatsEntry {
        TripStatsEntry(
            date: Date(),
            stats: TripStatsData(
                totalTrips: 12,
                upcomingTrips: 3,
                activeTrips: 1,
                totalSpent: 8500.0,
                totalBudget: 12000.0
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripStatsEntry) -> Void) {
        let stats = loadStats()
        completion(TripStatsEntry(date: Date(), stats: stats))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripStatsEntry>) -> Void) {
        let stats = loadStats()
        let entry = TripStatsEntry(date: Date(), stats: stats)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadStats() -> TripStatsData? {
        // Load from SwiftData using WidgetDataLoader
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // Calculate statistics
        let totalTrips = trips.count
        let upcomingTrips = trips.filter { $0.startDate > now }.count
        let activeTrips = trips.filter { $0.startDate <= now && $0.endDate >= now }.count
        let totalSpent = trips.reduce(0.0) { total, trip in
            total + (trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0)
        }
        let totalBudget = trips.reduce(0.0) { total, trip in
            total + (trip.budget ?? 0.0)
        }
        
        print("✅ Widget: Loaded stats - Total: \(totalTrips), Upcoming: \(upcomingTrips), Active: \(activeTrips)")
        
        return TripStatsData(
            totalTrips: totalTrips,
            upcomingTrips: upcomingTrips,
            activeTrips: activeTrips,
            totalSpent: totalSpent,
            totalBudget: totalBudget
        )
    }
}

struct TripStatsWidgetView: View {
    var entry: TripStatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemMedium {
            MediumStatsWidget(stats: entry.stats)
        } else {
            LargeStatsWidget(stats: entry.stats)
        }
    }
}

struct MediumStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Stats Grid
                HStack(spacing: 16) {
                    WidgetStatItem(icon: "airplane", value: "\(stats.totalTrips)", label: "Total")
                    WidgetStatItem(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming")
                    WidgetStatItem(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active")
                }
                
                // Budget
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct LargeStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Trip Counts
                HStack(spacing: 20) {
                    WidgetStatCard(icon: "airplane", value: "\(stats.totalTrips)", label: "Total Trips", color: .blue)
                    WidgetStatCard(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming", color: .orange)
                    WidgetStatCard(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active", color: .green)
                }
                
                // Budget Section
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Overview")
                                .font(.headline)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                            .frame(height: 8)
                        
                        Text("\(Int((stats.totalSpent / stats.totalBudget) * 100))% of budget used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct WidgetStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WidgetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Statistics Available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing trip statistics
//

import WidgetKit
import SwiftUI

struct TripStatsWidget: Widget {
    let kind: String = "TripStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripStatsProvider()) { entry in
            TripStatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trip Statistics")
        .description("Shows your trip statistics and overview")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TripStatsDataV2V2 {
    let totalTrips: Int
    let upcomingTrips: Int
    let activeTrips: Int
    let totalSpent: Double
    let totalBudget: Double
}

struct TripStatsEntry: TimelineEntry {
    let date: Date
    let stats: TripStatsData?
}

struct TripStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripStatsEntry {
        TripStatsEntry(
            date: Date(),
            stats: TripStatsData(
                totalTrips: 12,
                upcomingTrips: 3,
                activeTrips: 1,
                totalSpent: 8500.0,
                totalBudget: 12000.0
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripStatsEntry) -> Void) {
        let stats = loadStats()
        completion(TripStatsEntry(date: Date(), stats: stats))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripStatsEntry>) -> Void) {
        let stats = loadStats()
        let entry = TripStatsEntry(date: Date(), stats: stats)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadStats() -> TripStatsData? {
        // Load from SwiftData using WidgetDataLoader
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // Calculate statistics
        let totalTrips = trips.count
        let upcomingTrips = trips.filter { $0.startDate > now }.count
        let activeTrips = trips.filter { $0.startDate <= now && $0.endDate >= now }.count
        let totalSpent = trips.reduce(0.0) { total, trip in
            total + (trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0)
        }
        let totalBudget = trips.reduce(0.0) { total, trip in
            total + (trip.budget ?? 0.0)
        }
        
        print("✅ Widget: Loaded stats - Total: \(totalTrips), Upcoming: \(upcomingTrips), Active: \(activeTrips)")
        
        return TripStatsData(
            totalTrips: totalTrips,
            upcomingTrips: upcomingTrips,
            activeTrips: activeTrips,
            totalSpent: totalSpent,
            totalBudget: totalBudget
        )
    }
}

struct TripStatsWidgetView: View {
    var entry: TripStatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemMedium {
            MediumStatsWidget(stats: entry.stats)
        } else {
            LargeStatsWidget(stats: entry.stats)
        }
    }
}

struct MediumStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Stats Grid
                HStack(spacing: 16) {
                    WidgetStatItem(icon: "airplane", value: "\(stats.totalTrips)", label: "Total")
                    WidgetStatItem(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming")
                    WidgetStatItem(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active")
                }
                
                // Budget
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct LargeStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Trip Counts
                HStack(spacing: 20) {
                    WidgetStatCard(icon: "airplane", value: "\(stats.totalTrips)", label: "Total Trips", color: .blue)
                    WidgetStatCard(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming", color: .orange)
                    WidgetStatCard(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active", color: .green)
                }
                
                // Budget Section
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Overview")
                                .font(.headline)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                            .frame(height: 8)
                        
                        Text("\(Int((stats.totalSpent / stats.totalBudget) * 100))% of budget used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct WidgetStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WidgetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Statistics Available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing trip statistics
//

import WidgetKit
import SwiftUI

struct TripStatsWidget: Widget {
    let kind: String = "TripStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripStatsProvider()) { entry in
            TripStatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trip Statistics")
        .description("Shows your trip statistics and overview")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TripStatsDataV3V3 {
    let totalTrips: Int
    let upcomingTrips: Int
    let activeTrips: Int
    let totalSpent: Double
    let totalBudget: Double
}

struct TripStatsEntry: TimelineEntry {
    let date: Date
    let stats: TripStatsData?
}

struct TripStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripStatsEntry {
        TripStatsEntry(
            date: Date(),
            stats: TripStatsData(
                totalTrips: 12,
                upcomingTrips: 3,
                activeTrips: 1,
                totalSpent: 8500.0,
                totalBudget: 12000.0
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripStatsEntry) -> Void) {
        let stats = loadStats()
        completion(TripStatsEntry(date: Date(), stats: stats))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripStatsEntry>) -> Void) {
        let stats = loadStats()
        let entry = TripStatsEntry(date: Date(), stats: stats)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadStats() -> TripStatsData? {
        // Load from SwiftData using WidgetDataLoader
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // Calculate statistics
        let totalTrips = trips.count
        let upcomingTrips = trips.filter { $0.startDate > now }.count
        let activeTrips = trips.filter { $0.startDate <= now && $0.endDate >= now }.count
        let totalSpent = trips.reduce(0.0) { total, trip in
            total + (trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0)
        }
        let totalBudget = trips.reduce(0.0) { total, trip in
            total + (trip.budget ?? 0.0)
        }
        
        print("✅ Widget: Loaded stats - Total: \(totalTrips), Upcoming: \(upcomingTrips), Active: \(activeTrips)")
        
        return TripStatsData(
            totalTrips: totalTrips,
            upcomingTrips: upcomingTrips,
            activeTrips: activeTrips,
            totalSpent: totalSpent,
            totalBudget: totalBudget
        )
    }
}

struct TripStatsWidgetView: View {
    var entry: TripStatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemMedium {
            MediumStatsWidget(stats: entry.stats)
        } else {
            LargeStatsWidget(stats: entry.stats)
        }
    }
}

struct MediumStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Stats Grid
                HStack(spacing: 16) {
                    WidgetStatItem(icon: "airplane", value: "\(stats.totalTrips)", label: "Total")
                    WidgetStatItem(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming")
                    WidgetStatItem(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active")
                }
                
                // Budget
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct LargeStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Trip Counts
                HStack(spacing: 20) {
                    WidgetStatCard(icon: "airplane", value: "\(stats.totalTrips)", label: "Total Trips", color: .blue)
                    WidgetStatCard(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming", color: .orange)
                    WidgetStatCard(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active", color: .green)
                }
                
                // Budget Section
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Overview")
                                .font(.headline)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                            .frame(height: 8)
                        
                        Text("\(Int((stats.totalSpent / stats.totalBudget) * 100))% of budget used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct WidgetStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WidgetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Statistics Available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}


//  Itinero
//
//  Widget showing trip statistics
//

import WidgetKit
import SwiftUI

struct TripStatsWidget: Widget {
    let kind: String = "TripStatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripStatsProvider()) { entry in
            TripStatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Trip Statistics")
        .description("Shows your trip statistics and overview")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TripStatsDataV4V4 {
    let totalTrips: Int
    let upcomingTrips: Int
    let activeTrips: Int
    let totalSpent: Double
    let totalBudget: Double
}

struct TripStatsEntry: TimelineEntry {
    let date: Date
    let stats: TripStatsData?
}

struct TripStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TripStatsEntry {
        TripStatsEntry(
            date: Date(),
            stats: TripStatsData(
                totalTrips: 12,
                upcomingTrips: 3,
                activeTrips: 1,
                totalSpent: 8500.0,
                totalBudget: 12000.0
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TripStatsEntry) -> Void) {
        let stats = loadStats()
        completion(TripStatsEntry(date: Date(), stats: stats))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TripStatsEntry>) -> Void) {
        let stats = loadStats()
        let entry = TripStatsEntry(date: Date(), stats: stats)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
    
    private func loadStats() -> TripStatsData? {
        // Load from SwiftData using WidgetDataLoader
        let trips = WidgetDataLoader.loadTrips()
        let now = Date()
        
        // Calculate statistics
        let totalTrips = trips.count
        let upcomingTrips = trips.filter { $0.startDate > now }.count
        let activeTrips = trips.filter { $0.startDate <= now && $0.endDate >= now }.count
        let totalSpent = trips.reduce(0.0) { total, trip in
            total + (trip.expenses?.reduce(0.0) { $0 + $1.amount } ?? 0.0)
        }
        let totalBudget = trips.reduce(0.0) { total, trip in
            total + (trip.budget ?? 0.0)
        }
        
        print("✅ Widget: Loaded stats - Total: \(totalTrips), Upcoming: \(upcomingTrips), Active: \(activeTrips)")
        
        return TripStatsData(
            totalTrips: totalTrips,
            upcomingTrips: upcomingTrips,
            activeTrips: activeTrips,
            totalSpent: totalSpent,
            totalBudget: totalBudget
        )
    }
}

struct TripStatsWidgetView: View {
    var entry: TripStatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if family == .systemMedium {
            MediumStatsWidget(stats: entry.stats)
        } else {
            LargeStatsWidget(stats: entry.stats)
        }
    }
}

struct MediumStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Stats Grid
                HStack(spacing: 16) {
                    WidgetStatItem(icon: "airplane", value: "\(stats.totalTrips)", label: "Total")
                    WidgetStatItem(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming")
                    WidgetStatItem(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active")
                }
                
                // Budget
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Total Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                    }
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct LargeStatsWidget: View {
    let stats: TripStatsData?
    
    var body: some View {
        if let stats = stats {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Trip Statistics")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Divider()
                
                // Trip Counts
                HStack(spacing: 20) {
                    WidgetStatCard(icon: "airplane", value: "\(stats.totalTrips)", label: "Total Trips", color: .blue)
                    WidgetStatCard(icon: "calendar.badge.plus", value: "\(stats.upcomingTrips)", label: "Upcoming", color: .orange)
                    WidgetStatCard(icon: "airplane.departure", value: "\(stats.activeTrips)", label: "Active", color: .green)
                }
                
                // Budget Section
                if stats.totalBudget > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Budget Overview")
                                .font(.headline)
                            Spacer()
                            Text("$\(Int(stats.totalSpent)) / $\(Int(stats.totalBudget))")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: min(stats.totalSpent, stats.totalBudget), total: max(stats.totalBudget, 0.1))
                            .tint(.green)
                            .frame(height: 8)
                        
                        Text("\(Int((stats.totalSpent / stats.totalBudget) * 100))% of budget used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
            .containerBackground(.fill.tertiary, for: .widget)
        } else {
            EmptyStatsView()
        }
    }
}

struct WidgetStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WidgetStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct EmptyStatsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Statistics Available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

