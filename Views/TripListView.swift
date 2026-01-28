//
//  TripListView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import WidgetKit

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \TripModel.startDate, order: .forward) private var trips: [TripModel]
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingAddTrip = false
    @State private var showingSettings = false
    @State private var selectedTripForDetail: TripModel?
    @State private var showingPaywall = false
    @State private var limitAlertMessage: String?
    @State private var showLimitAlert = false
    
    private var categories: [String] {
        ["All", "Adventure", "Business", "Relaxation", "Family", "General"]
    }
    
    // Computed property that ensures reactivity by accessing published properties
    private var themeBackgroundColor: Color {
        // Access published properties to ensure SwiftUI tracks changes
        let currentTheme = themeManager.currentTheme
        let defaultPalette = themeManager.defaultPalette
        let activeCustomThemeID = themeManager.activeCustomThemeID
        let customThemes = themeManager.customThemes
        let customAccentColor = themeManager.customAccentColor
        
        // Use the values to ensure reactivity
        _ = currentTheme
        _ = defaultPalette
        _ = activeCustomThemeID
        _ = customThemes
        _ = customAccentColor
        
        return themeManager.currentPalette.background
    }
    
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
        let bgColor = themeBackgroundColor
        return NavigationStack {
            ZStack {
                // Theme background - reactive to theme changes
                bgColor
                    .ignoresSafeArea()
                
                if trips.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Search Bar
                            SearchBar(text: $searchText)
                            
                            // Enhanced Stats Card
                            EnhancedStatsCardView(trips: trips)
                                .padding(.horizontal)
                            
                            // Current Trips
                            if !currentTrips.isEmpty {
                                TripSectionView(title: "Current Trips", trips: currentTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail)
                            }
                            
                            // Upcoming Trips
                            if !upcomingTrips.isEmpty {
                                TripSectionView(title: "Upcoming", trips: upcomingTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail)
                            }
                            
                            // Past Trips
                            if !pastTrips.isEmpty {
                                TripSectionView(title: "Past Trips", trips: pastTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("My Trips")
            .background(themeBackgroundColor)
            // .observeLanguage() // Method not available
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let check = proLimiter.canCreateTrip(currentTripCount: trips.count)
                        if check.allowed {
                            showingAddTrip = true
                        } else {
                            limitAlertMessage = check.reason
                            showLimitAlert = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingAddTrip) {
                NavigationStack {
                    AddTripView()
                }
            }
            .fullScreenCover(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                        .environmentObject(themeManager)
                }
            }
            .onAppear {
                // Load settings asynchronously (non-blocking)
                Task {
                    SettingsManager.shared.createDefaultSettings(in: modelContext)
                    SettingsManager.shared.loadSettings(from: modelContext)
                }
                
                // Sync trips to widgets on appear
                Task { @MainActor in
                    let allTrips = try? modelContext.fetch(FetchDescriptor<TripModel>())
                    if let trips = allTrips {
                        WidgetDataSync.shared.syncTrips(trips)
                    }
                }
            }
            .onChange(of: trips.count) { _, _ in
                // Sync whenever trips change
                Task { @MainActor in
                    WidgetDataSync.shared.syncTrips(trips)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTrip"))) { notification in
                if let userInfo = notification.userInfo,
                   let tripIdString = userInfo["tripId"] as? String,
                   let tripId = UUID(uuidString: tripIdString),
                   let trip = trips.first(where: { $0.id == tripId }) {
                    selectedTripForDetail = trip
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToActiveTrip"))) { _ in
                if let activeTrip = trips.first(where: { $0.isCurrent }) {
                    selectedTripForDetail = activeTrip
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToUpcomingTrips"))) { _ in
                // Scroll to upcoming trips section
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAddTrip"))) { _ in
                showingAddTrip = true
            }
            .fullScreenCover(item: $selectedTripForDetail) { trip in
                NavigationStack {
                    TripDetailView(trip: trip)
                }
            }
            .alert("Limit Reached", isPresented: $showLimitAlert) {
                Button("Upgrade to Pro") {
                    showingPaywall = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let message = limitAlertMessage {
                    Text(message)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                NavigationStack {
                    PaywallView()
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search", text: $text)
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

struct TripSectionView: View {
    let title: String
    let trips: [TripModel]
    let modelContext: ModelContext
    @Binding var selectedTripForDetail: TripModel?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                EnhancedTripCardWrapper(
                    trip: trip,
                    onCardTap: {
                        selectedTripForDetail = trip
                    }
                )
                .padding(.horizontal)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                        HapticManager.shared.error()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        duplicateTrip(trip)
                        HapticManager.shared.success()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: trips.count)
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
    
    private func duplicateTrip(_ trip: TripModel) {
        let duplicatedTrip = TripModel(
            name: "\(trip.name) (Copy)",
            startDate: trip.startDate,
            endDate: trip.endDate,
            notes: trip.notes,
            category: trip.category,
            budget: trip.budget
        )
        
        // Copy destinations
        if let destinations = trip.destinations, !destinations.isEmpty {
            duplicatedTrip.destinations = []
            for (index, destination) in destinations.enumerated() {
                let newDestination = DestinationModel(
                    name: destination.name,
                    address: destination.address,
                    notes: destination.notes,
                    order: index
                )
                modelContext.insert(newDestination)
                duplicatedTrip.destinations?.append(newDestination)
            }
        }
        
        modelContext.insert(duplicatedTrip)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to duplicate trip: \(error)")
        }
    }
}

struct EnhancedTripCardWrapper: View {
    let trip: TripModel
    let onCardTap: () -> Void
    
    var body: some View {
        Button(action: onCardTap) {
            EnhancedTripCard(trip: trip)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct TripRowView: View {
    let trip: TripModel
    private let settingsManager = SettingsManager.shared
    
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
                            Image(systemName: SettingsManager.shared.currencyIconName())
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(SettingsManager.shared.formatAmount(budget))
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
                    Text("days")
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
            
            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start planning your next adventure!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        // .observeLanguage() // Method not available
    }
}

// Enhanced Stats Card with multiple metrics
struct EnhancedStatsCardView: View {
    let trips: [TripModel]
    
    private var totalDays: Int { trips.reduce(0) { $0 + $1.duration } }
    private var totalTrips: Int { trips.count }
    private var upcomingCount: Int { trips.filter { $0.isUpcoming }.count }
    private var currentCount: Int { trips.filter { $0.isCurrent }.count }
    private var totalDestinations: Int { trips.reduce(0) { $0 + ($1.destinations?.count ?? 0) } }
    private var totalBudget: Double { trips.compactMap { $0.budget }.reduce(0, +) }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main stats row
            HStack(spacing: 16) {
                StatsCardItem(
                    icon: "airplane.departure",
                    value: "\(totalTrips)",
                    label: "Total Trips",
                    color: .blue
                )
                StatsCardItem(
                    icon: "clock.fill",
                    value: "\(totalDays)",
                    label: "days",
                    color: .orange
                )
                StatsCardItem(
                    icon: "mappin.circle.fill",
                    value: "\(totalDestinations)",
                    label: "Destinations",
                    color: .green
                )
            }
            
            // Secondary stats row
            HStack(spacing: 16) {
                StatsCardItem(
                    icon: "calendar.badge.clock",
                    value: "\(upcomingCount)",
                    label: "Upcoming",
                    color: .purple
                )
                StatsCardItem(
                    icon: "airplane.departure",
                    value: "\(currentCount)",
                    label: "Current Trips",
                    color: .blue
                )
                if totalBudget > 0 {
                    StatsCardItem(
                        icon: SettingsManager.shared.currencyIconName(),
                        value: SettingsManager.shared.formatAmount(totalBudget),
                        label: "Total Budget",
                        color: .green
                    )
                } else {
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

private struct StatsCardItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}



#Preview {
    NavigationStack {
        TripListView()
            .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
    }
}

