//
//  TripListView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripModel.startDate, order: .forward) private var trips: [TripModel]
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingAddTrip = false
    @State private var showingStats = false
    @State private var showingAnalytics = false
    @State private var showingSettings = false
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private let categories = ["All", "Adventure", "Business", "Relaxation", "Family", "General"]
    
    var filteredTrips: [TripModel] {
        var result = trips
        
        if !searchText.isEmpty {
            result = result.filter { trip in
                trip.name.localizedCaseInsensitiveContains(searchText) ||
                trip.notes.localizedCaseInsensitiveContains(searchText) ||
                trip.destinations?.contains { $0.name.localizedCaseInsensitiveContains(searchText) } ?? false
            }
        }
        
        if let category = selectedCategory, category != "All" {
            result = result.filter { $0.category == category }
        }
        
        return result
    }
    
    var upcomingTrips: [TripModel] {
        filteredTrips.filter { $0.isUpcoming }
    }
    
    var currentTrips: [TripModel] {
        filteredTrips.filter { $0.isCurrent }
    }
    
    var pastTrips: [TripModel] {
        filteredTrips.filter { $0.isPast }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if trips.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            SearchBar(text: $searchText)
                            
                            // Category Filter
                            CategoryFilterView(selectedCategory: $selectedCategory, categories: categories)
                            
                            // Statistics Card with animation
                            StatisticsCardView(trips: trips)
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            
                            // Current Trips
                            if !currentTrips.isEmpty {
                                TripSectionView(title: "trips.current".localized, trips: currentTrips, modelContext: modelContext)
                            }
                            
                            // Upcoming Trips
                            if !upcomingTrips.isEmpty {
                                TripSectionView(title: "trips.upcoming".localized, trips: upcomingTrips, modelContext: modelContext)
                            }
                            
                            // Past Trips
                            if !pastTrips.isEmpty {
                                TripSectionView(title: "trips.past".localized, trips: pastTrips, modelContext: modelContext)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("trips.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingStats = true }) {
                            Label("statistics.title".localized, systemImage: "chart.bar")
                        }
                        Button(action: { showingAnalytics = true }) {
                            Label("analytics.title".localized, systemImage: "chart.line.uptrend.xyaxis")
                        }
                        Button(action: { showingSettings = true }) {
                            Label("settings.title".localized, systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTrip) {
                NavigationStack {
                    AddTripView()
                }
            }
            .sheet(isPresented: $showingStats) {
                StatisticsView(trips: trips)
            }
            .sheet(isPresented: $showingAnalytics) {
                NavigationStack {
                    AnalyticsView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                // Load settings asynchronously (non-blocking)
                Task {
                    settingsManager.createDefaultSettings(in: modelContext)
                    settingsManager.loadSettings(from: modelContext)
                }
            }
            .refreshOnLanguageChange()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("common.search".localized, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CategoryFilterView: View {
    @Binding var selectedCategory: String?
    let categories: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: (selectedCategory ?? "") == category || (selectedCategory == nil && category == "All")
                    ) {
                        selectedCategory = category == "All" ? nil : category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

struct StatisticsCardView: View {
    let trips: [TripModel]
    
    var totalTrips: Int { trips.count }
    var upcomingCount: Int { trips.filter { $0.isUpcoming }.count }
    var totalDays: Int { trips.reduce(0) { $0 + $1.duration } }
    
    var body: some View {
        HStack(spacing: 20) {
            StatItemView(value: "\(totalTrips)", label: "Trips", icon: "airplane")
            StatItemView(value: "\(upcomingCount)", label: "Upcoming", icon: "calendar")
            StatItemView(value: "\(totalDays)", label: "Days", icon: "clock")
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

struct StatItemView: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TripSectionView: View {
    let title: String
    let trips: [TripModel]
    let modelContext: ModelContext
    @State private var selectedTripForMap: TripModel? = nil
    @State private var selectedTripForCalendar: TripModel? = nil
    @State private var selectedTripForVoiceNotes: TripModel? = nil
    @State private var showMap = false
    @State private var showCalendar = false
    @State private var showVoiceNotes = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                NavigationLink(destination: TripDetailView(trip: trip)) {
                    EnhancedTripCard(
                        trip: trip,
                        onMapTap: {
                            selectedTripForMap = trip
                            showMap = true
                        },
                        onCalendarTap: {
                            selectedTripForCalendar = trip
                            showCalendar = true
                        },
                        onVoiceNotesTap: {
                            selectedTripForVoiceNotes = trip
                            showVoiceNotes = true
                        }
                    )
                    .padding(.horizontal)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                        HapticManager.shared.error()
                    } label: {
                        Label("common.delete".localized, systemImage: "trash")
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: trips.count)
            }
        }
        .sheet(isPresented: $showMap) {
            if let trip = selectedTripForMap {
                NavigationStack {
                    TripMapView(trip: trip)
                }
            }
        }
        .sheet(isPresented: $showCalendar) {
            if let trip = selectedTripForCalendar {
                NavigationStack {
                    TripCalendarView(trip: trip)
                }
            }
        }
        .sheet(isPresented: $showVoiceNotes) {
            if let trip = selectedTripForVoiceNotes {
                NavigationStack {
                    VoiceNotesView(trip: trip)
                }
            }
        }
    }
    
    private func deleteTrip(_ trip: TripModel) {
        modelContext.delete(trip)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete trip: \(error)")
        }
    }
}

struct TripRowView: View {
    let trip: TripModel
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(trip.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        CategoryBadge(category: trip.category)
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(trip.formattedDateRange)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let destinations = trip.destinations, !destinations.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(trip.destinations?.count ?? 0) destination\(trip.destinations?.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let budget = trip.budget {
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(settingsManager.formatAmount(budget))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                VStack {
                    Text("\(trip.duration)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("trips.days".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CategoryBadge: View {
    let category: String
    
    var color: Color {
        switch category {
        case "Adventure": return .orange
        case "Business": return .blue
        case "Relaxation": return .green
        case "Family": return .pink
        default: return .gray
        }
    }
    
    var body: some View {
        Text(category)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("trips.empty".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("trips.empty.description".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        TripListView()
            .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
    }
}
