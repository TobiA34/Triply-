//
//  TripListView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import WidgetKit

/// How trips are ordered within each section (Current / Upcoming / Past).
private enum TripListSortOrder: String, CaseIterable, Identifiable {
    case startDateAscending
    case startDateDescending
    case nameAZ
    case nameZA

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .startDateAscending: return "trips.sort.startDateAsc".localized
        case .startDateDescending: return "trips.sort.startDateDesc".localized
        case .nameAZ: return "trips.sort.nameAZ".localized
        case .nameZA: return "trips.sort.nameZA".localized
        }
    }
}

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
    @State private var contentAppeared = false
    @State private var sortOrder: TripListSortOrder = .startDateAscending
    
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

    private func applySort(_ list: [TripModel]) -> [TripModel] {
        switch sortOrder {
        case .startDateAscending:
            return list.sorted { $0.startDate < $1.startDate }
        case .startDateDescending:
            return list.sorted { $0.startDate > $1.startDate }
        case .nameAZ:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameZA:
            return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }
    
    var upcomingTrips: [TripModel] {
        applySort(filteredTrips.filter { $0.isUpcoming })
    }
    
    var currentTrips: [TripModel] {
        applySort(filteredTrips.filter { $0.isCurrent })
    }
    
    var pastTrips: [TripModel] {
        applySort(filteredTrips.filter { $0.isPast })
    }

    private var tripListScrollContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            TripListHeroHeader()
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.xs)
            if !proLimiter.isPro {
                ProHomePaywallBanner {
                    Task {
                        if await IAPManager.shared.preparePaywall() {
                            showingPaywall = true
                        }
                    }
                }
                .environmentObject(themeManager)
            }
            SearchBar(text: $searchText)
            HStack {
                Spacer(minLength: 0)
                Menu {
                    ForEach(TripListSortOrder.allCases) { option in
                        Button {
                            sortOrder = option
                            HapticManager.shared.selection()
                        } label: {
                            if sortOrder == option {
                                Label(option.localizedTitle, systemImage: "checkmark")
                            } else {
                                Text(option.localizedTitle)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title3)
                        Text("trips.sort".localized)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(themeManager.currentPalette.accent)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(themeManager.currentPalette.accent.opacity(0.12))
                    )
                }
                .accessibilityLabel("trips.sort".localized)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            EnhancedStatsCardView(trips: trips)
                .padding(.horizontal, DesignSystem.Spacing.md)
            if !currentTrips.isEmpty {
                TripSectionView(title: "trips.current".localized, trips: currentTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail, contentAppeared: contentAppeared)
            }
            if !upcomingTrips.isEmpty {
                TripSectionView(title: "trips.upcoming".localized, trips: upcomingTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail, contentAppeared: contentAppeared)
            }
            if !pastTrips.isEmpty {
                TripSectionView(title: "trips.past".localized, trips: pastTrips, modelContext: modelContext, selectedTripForDetail: $selectedTripForDetail, contentAppeared: contentAppeared)
            }
        }
        .padding(.vertical)
    }

    private var tripListMainContent: some View {
        ZStack {
            themeBackgroundColor
                .ignoresSafeArea()
            if trips.isEmpty {
                EmptyStateView(onCreateTap: {
                    let check = proLimiter.canCreateTrip(currentTripCount: trips.count)
                    if check.allowed { showingAddTrip = true }
                    else { limitAlertMessage = check.reason; showLimitAlert = true }
                })
            } else {
                ScrollView {
                    tripListScrollContent
                }
                .refreshable {
                    await MainActor.run {
                        WidgetDataSync.shared.syncTrips(trips)
                        WidgetCenter.shared.reloadAllTimelines()
                        HapticManager.shared.selection()
                    }
                }
                .opacity(contentAppeared ? 1 : 0)
                .onAppear {
                    if !trips.isEmpty {
                        withAnimation(DesignSystem.Animation.springBouncy) {
                            contentAppeared = true
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            tripListMainContent
            .onChange(of: trips.isEmpty) { _, isEmpty in
                if isEmpty { contentAppeared = false }
            }
            .navigationTitle("trips.title".localized)
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
                    .accessibilityLabel("trips.addTrip".localized)
                    .accessibilityHint("Opens the form to create a new trip")
                    .accessibilityIdentifier("Add Trip")
                }
            }
            .fullScreenCover(isPresented: $showingAddTrip) {
                NavigationStack {
                    AddTripView()
                        .environmentObject(themeManager)
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
                checkPendingDeepLink()
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
                } else {
                    checkPendingDeepLink()
                }
            }
            .onAppear {
                checkPendingDeepLink()
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
                        .environmentObject(themeManager)
                }
            }
            .alert("alert.limitReached".localized, isPresented: $showLimitAlert) {
                Button("pro.upgrade".localized) {
                    Task {
                        if await IAPManager.shared.preparePaywall() {
                            showingPaywall = true
                        }
                    }
                }
                Button("common.cancel".localized, role: .cancel) { }
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
    
    /// Opens trip from cold-launch deep link when trips are available.
    private func checkPendingDeepLink() {
        guard let idString = UserDefaults.standard.string(forKey: "PendingOpenTripId"),
              let tripId = UUID(uuidString: idString),
              let trip = trips.first(where: { $0.id == tripId }) else { return }
        UserDefaults.standard.removeObject(forKey: "PendingOpenTripId")
        selectedTripForDetail = trip
    }
}

struct SearchBar: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.currentPalette.secondaryText)
            TextField("search.placeholder".localized, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    HapticManager.shared.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentPalette.background.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(themeManager.currentPalette.accent.opacity(0.12), lineWidth: 1)
                )
        )
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
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.currentPalette.text)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(isSelected ? themeManager.currentPalette.accent : Color(.systemGray5))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

struct TripSectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let trips: [TripModel]
    let modelContext: ModelContext
    @Binding var selectedTripForDetail: TripModel?
    var contentAppeared: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentPalette.text)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
                EnhancedTripCardWrapper(
                    trip: trip,
                    onCardTap: {
                        HapticManager.shared.selection()
                        selectedTripForDetail = trip
                    }
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteTrip(trip)
                        HapticManager.shared.error()
                    } label: {
                        Label("common.delete".localized, systemImage: "trash")
                    }
                    
                    Button {
                        duplicateTrip(trip)
                        HapticManager.shared.success()
                    } label: {
                        Label("trips.duplicate".localized, systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 14)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .animation(.spring(response: 0.52, dampingFraction: 0.82).delay(Double(index) * 0.06), value: contentAppeared)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: trips.count)
                .contextMenu {
                    Button {
                        HapticManager.shared.selection()
                        selectedTripForDetail = trip
                    } label: {
                        Label("trips.openTrip".localized, systemImage: "arrow.right.circle")
                    }
                    Button {
                        duplicateTrip(trip)
                        HapticManager.shared.success()
                    } label: {
                        Label("trips.duplicate".localized, systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        deleteTrip(trip)
                        HapticManager.shared.error()
                    } label: {
                        Label("common.delete".localized, systemImage: "trash")
                    }
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.96 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Trip list hero (fun, travel-exciting home header)
struct TripListHeroHeader: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var appeared = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.currentPalette.accent,
                                themeManager.currentPalette.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: themeManager.currentPalette.accent.opacity(0.35), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text("trips.title".localized)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(themeManager.currentPalette.text)
                Text("trips.hero.tagline".localized)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentPalette.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentPalette.background.opacity(0.92))
                .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 24, x: 0, y: 12)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(DesignSystem.Animation.springBouncy) {
                appeared = true
            }
        }
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
                    Text("tripListView.tripduration".localized)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.25))
                    Text("trips.days".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.95, green: 0.5, blue: 0.35).opacity(0.15))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(red: 1.0, green: 0.99, blue: 0.98))
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
    
    private var localizedCategory: String {
        switch category {
        case "Adventure": return "category.adventure".localized
        case "Business": return "category.business".localized
        case "Relaxation": return "category.relaxation".localized
        case "Family": return "category.family".localized
        case "General": return "category.general".localized
        default: return category
        }
    }
    
    var body: some View {
        Text(localizedCategory)
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
    @EnvironmentObject var themeManager: ThemeManager
    var onCreateTap: (() -> Void)?
    @State private var iconAppeared = false
    @State private var textAppeared = false
    @State private var buttonAppeared = false
    @State private var floatPhase: CGFloat = 0

    private let travelIcons = ["airplane.departure", "map.fill", "sun.max.fill", "globe.americas.fill"]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Energetic cluster of travel icons
            ZStack {
                ForEach(Array(travelIcons.enumerated()), id: \.offset) { i, name in
                    let angle = Double(i) * .pi / 2 + floatPhase * .pi * 0.5
                    let r: CGFloat = 52 + CGFloat(i % 2) * 8
                    Image(systemName: name)
                        .font(.system(size: i == 0 ? 44 : 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    themeManager.currentPalette.accent,
                                    themeManager.currentPalette.accent.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(x: cos(angle) * r * 0.4, y: sin(angle) * r * 0.4)
                        .opacity(iconAppeared ? 1 : 0)
                        .scaleEffect(iconAppeared ? 1 : 0.3)
                }
                Circle()
                    .fill(themeManager.currentPalette.accent.opacity(0.08))
                    .frame(width: 140, height: 140)
                    .blur(radius: 2)
                    .scaleEffect(iconAppeared ? 1 : 0.6)
            }
            .padding(.top, DesignSystem.Spacing.xxl)
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    floatPhase = 1
                }
            }

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("trips.empty".localized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentPalette.text)
                Text("trips.empty.description.long".localized)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .opacity(textAppeared ? 1 : 0)
            .offset(y: textAppeared ? 0 : 12)

            if let action = onCreateTap {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    action()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("trips.empty.createFirst".localized)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeManager.currentPalette.accent,
                                        themeManager.currentPalette.accent.opacity(0.85)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                .padding(.top, DesignSystem.Spacing.sm)
                .scaleEffect(buttonAppeared ? 1 : 0.9)
                .opacity(buttonAppeared ? 1 : 0)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .onAppear {
            withAnimation(DesignSystem.Animation.springBouncy) {
                iconAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animation.spring) {
                    textAppeared = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(DesignSystem.Animation.spring) {
                    buttonAppeared = true
                }
            }
        }
    }
}

// Enhanced Stats Card – travel-energetic look
struct EnhancedStatsCardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let trips: [TripModel]
    @State private var appeared = false

    private var totalDays: Int { trips.reduce(0) { $0 + $1.duration } }
    private var totalTrips: Int { trips.count }
    private var upcomingCount: Int { trips.filter { $0.isUpcoming }.count }
    private var currentCount: Int { trips.filter { $0.isCurrent }.count }
    private var totalDestinations: Int { trips.reduce(0) { $0 + ($1.destinations?.count ?? 0) } }
    private var totalBudget: Double { trips.compactMap { $0.budget }.reduce(0, +) }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatsCardItem(
                    icon: "airplane.departure",
                    value: "\(totalTrips)",
                    label: "trips.totalTrips".localized,
                    color: .blue
                )
                StatsCardItem(
                    icon: "clock.fill",
                    value: "\(totalDays)",
                    label: "trips.days".localized,
                    color: .orange
                )
                StatsCardItem(
                    icon: "mappin.circle.fill",
                    value: "\(totalDestinations)",
                    label: "destination.title".localized,
                    color: .green
                )
            }

            HStack(spacing: 16) {
                StatsCardItem(
                    icon: "calendar.badge.clock",
                    value: "\(upcomingCount)",
                    label: "trips.upcoming".localized,
                    color: .purple
                )
                StatsCardItem(
                    icon: "airplane.departure",
                    value: "\(currentCount)",
                    label: "trips.current".localized,
                    color: .blue
                )
                if totalBudget > 0 {
                    StatsCardItem(
                        icon: SettingsManager.shared.currencyIconName(),
                        value: SettingsManager.shared.formatAmount(totalBudget),
                        label: "trips.totalBudgetLabel".localized,
                        color: .green
                    )
                } else {
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(themeManager.currentPalette.background)
                .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 24, x: 0, y: 10)
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 6)
        .onAppear {
            withAnimation(DesignSystem.Animation.springBouncy) {
                appeared = true
            }
        }
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

