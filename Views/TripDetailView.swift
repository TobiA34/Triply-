//
//  TripDetailView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import PhotosUI
import CoreImage

struct TripDetailView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEditTrip = false
    @State private var showingAddDestination = false
    @State private var showingShareSheet = false
    @State private var showingImagePicker = false
    @State private var showingSocialImport = false
    @State private var showingPaywall = false
    @State private var proFeatureTeaser: ProFeatureTeaserItem?
    // Pro / AI feature entry points
    @State private var showingPlanGenerator = false
    @State private var showingTripOptimizer = false
    @State private var showingBudgetInsights = false
    @State private var showingCollaborativeTrip = false
    @State private var showingSmartPacking = false
    @State private var showingExport = false
    @State private var showingAddToCalendar = false
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showingFullScreenImage = false
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var destinationSearchManager = DestinationSearchManager()
    @State private var searchSelectedDestinations: [SearchResult] = []
    
    private var tripDetailScrollBody: some View {
        VStack(spacing: 0) {
            TripHeroImageView(
                        image: trip.coverImageData.flatMap { UIImage(data: $0) },
                        tripName: trip.name,
                        category: trip.category,
                        dateRange: trip.formattedDateRange,
                        duration: trip.duration,
                        budget: trip.budget,
                        scrollOffset: $scrollOffset
                    )
                    .frame(height: 250)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Only show full-screen if an image is set
                        if trip.coverImageData != nil {
                            showingFullScreenImage = true
                        }
                    }
                    .overlay(
                        // Edit and Camera buttons - horizontal arrangement
                        HStack {
                            Spacer()
                            HStack(spacing: 12) {
                                // Edit button
                                Button(action: { showingEditTrip = true }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                                
                                // Camera/Photo button
                                Button(action: { showingImagePicker = true }) {
                                    Image(systemName: trip.coverImageData != nil ? "photo" : "camera.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                            }
                            .padding(.trailing, 18)
                            .padding(.top, 16)
                        }
                    )
                    
                    // Tab Selector - 3 core tabs (Overview / Itinerary / Packing)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            TabButton(title: "tripDetail.overview".localized, icon: "list.bullet", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            TabButton(title: "tripDetail.itineraryTab".localized, icon: "calendar", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            TabButton(title: "tripDetail.packingTab".localized, icon: "suitcase", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(
                        // Match hero image background to prevent white gap
                        Group {
                            if let imageData = trip.coverImageData, let image = UIImage(data: imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 50)
                                    .offset(y: -25)
                                    .clipped()
                                    .blur(radius: 20)
                            } else {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.5, blue: 0.35),
                                        Color(red: 1.0, green: 0.65, blue: 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                        .opacity(0.1)
                        .background(themeManager.currentPalette.background)
                    )
                    
                    // Content based on tab
                    Group {
                        // Overview Tab
                        if selectedTab == 0 {
                            VStack(alignment: .leading, spacing: 20) {
                                // Stats Card
                                TripStatsCard(trip: trip)
                                    .padding(.horizontal, 16)
                                
                                // Info Chips
                                TripInfoChips(category: trip.category, dateRange: trip.formattedDateRange)
                                
                                // Snapshot Tiles
                                SnapshotTilesGrid(trip: trip, selectedTab: $selectedTab)
                                    .padding(.horizontal, 16)

                                // Progress Card
                                TripProgressCard(trip: trip)
                                    .padding(.horizontal, 16)

                                // Primary Actions
                                TripPrimaryActionsRow(
                                    onShare: { showingShareSheet = true },
                                    onEdit: { showingEditTrip = true },
                                    onAddDestination: {
                                        let count = trip.destinations?.count ?? 0
                                        let check = ProLimiter.shared.canAddDestination(currentDestinationCount: count, tripName: trip.name)
                                        if check.allowed { showingAddDestination = true } else { proFeatureTeaser = .moreDestinations() }
                                    }
                                )
                                .padding(.horizontal, 16)
                                
                                // Pro & AI Tools (all gated; non‑Pro taps show paywall)
                                ProToolsRow(
                                    onPlanGenerator: {
                                        if ProLimiter.shared.isPro {
                                            showingPlanGenerator = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    },
                                    onOptimizer: {
                                        if ProLimiter.shared.isPro {
                                            showingTripOptimizer = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    },
                                    onBudgetInsights: {
                                        if ProLimiter.shared.isPro {
                                            showingBudgetInsights = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    },
                                    onCollaborate: {
                                        if ProLimiter.shared.isPro {
                                            showingCollaborativeTrip = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    },
                                    onSmartPacking: {
                                        if ProLimiter.shared.isPro {
                                            showingSmartPacking = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    },
                                    onExport: {
                                        if ProLimiter.shared.isPro {
                                            showingExport = true
                                        } else {
                                            showingPaywall = true
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                                
                                // Social Media Import Button (Pro Feature)
                                Button {
                                    let check = ProLimiter.shared.canAccessSocialMediaImport()
                                    if check.allowed {
                                        showingSocialImport = true
                                    } else {
                                        proFeatureTeaser = .socialImport()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("tripDetail.importSocial".localized)
                                        if !ProLimiter.shared.isPro {
                                            Image(systemName: "crown.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 16)
                                
                                // Destinations Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 8) {
                                        Text("destination.title".localized)
                                            .font(.title3.weight(.semibold))
                                        Spacer(minLength: 8)
                                        Button(action: {
                                            let count = trip.destinations?.count ?? 0
                                            let check = ProLimiter.shared.canAddDestination(currentDestinationCount: count, tripName: trip.name)
                                            if check.allowed { showingAddDestination = true } else { proFeatureTeaser = .moreDestinations() }
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    if trip.destinations?.isEmpty ?? true {
                                        EmptyDestinationsView()
                                    } else {
                                        VStack(spacing: 12) {
                                            ForEach(trip.destinations?.sorted(by: { $0.order < $1.order }) ?? [], id: \.id) { destination in
                                                DestinationCardView(destination: destination, trip: trip, modelContext: modelContext)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                
                                // Notes Section
                                if !trip.notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "note.text")
                                                .foregroundColor(themeManager.currentPalette.accent)
                                            Text("trips.notes".localized)
                                                .font(.title3.weight(.semibold))
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                        Text(trip.notes)
                                            .font(.body)
                                                .foregroundColor(themeManager.currentPalette.text)
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(4)
                                        }
                                        .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(themeManager.currentPalette.background)
                                                .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 8, x: 0, y: 4)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(themeManager.currentPalette.accent.opacity(0.12), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                        
                        // Itinerary Tab
                        if selectedTab == 1 {
                            ItineraryView(trip: trip)
                                .padding(.bottom, 100)
                        }
                        
                        // Packing List Tab
                        if selectedTab == 2 {
                            PackingListView(trip: trip)
                                .padding(.bottom, 100)
                        }
                    }
                }
    }

    var body: some View {
        GeometryReader { _ in
            ScrollView(showsIndicators: false) {
                tripDetailScrollBody
            }
            .background(
                GeometryReader { scrollGeometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: scrollGeometry.frame(in: .named("scroll")).minY
                        )
                }
            )
            .coordinateSpace(name: "scroll")
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("common.back".localized)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingShareSheet = true }) {
                        Label("tripDetail.share".localized, systemImage: "square.and.arrow.up")
                    }
                    if ProLimiter.shared.isPro {
                        Button(action: { showingExport = true }) {
                            Label("tripDetail.exportOptions".localized, systemImage: "doc.text")
                        }
                        Button(action: { showingAddToCalendar = true }) {
                            Label("tripDetail.addToCalendar".localized, systemImage: "calendar.badge.plus")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showingEditTrip) {
            EditTripView(trip: trip)
        }
        .fullScreenCover(isPresented: $showingAddDestination, onDismiss: applySelectedDestinationsFromSearch) {
            DestinationSearchView(
                searchManager: destinationSearchManager,
                selectedDestinations: $searchSelectedDestinations
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [tripShareText()])
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePickerView(onImageSelected: { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    trip.coverImageData = imageData
                    try? modelContext.save()
                }
            })
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(item: $proFeatureTeaser) { feature in
            ProFeatureTeaserSheet(
                feature: feature,
                onDismiss: { proFeatureTeaser = nil },
                onGoToPro: {}
            )
        }
        .sheet(isPresented: $showingSocialImport) {
            SocialMediaImportView(trip: trip)
        }
        .sheet(isPresented: $showingPlanGenerator) {
            NavigationStack {
                PlanGeneratorView(trip: trip)
            }
        }
        .sheet(isPresented: $showingTripOptimizer) {
            NavigationStack {
                InlineTripOptimizerView(trip: trip)
            }
        }
        .sheet(isPresented: $showingBudgetInsights) {
            NavigationStack {
                BudgetInsightsView(trip: trip)
            }
        }
        .sheet(isPresented: $showingCollaborativeTrip) {
            NavigationStack {
                InlineCollaborativeTripView(trip: trip)
            }
        }
        .sheet(isPresented: $showingSmartPacking) {
            NavigationStack {
                SmartPackingGeneratorView(trip: trip)
            }
        }
        .sheet(isPresented: $showingExport) {
            TripExportView(trip: trip)
        }
        .sheet(isPresented: $showingAddToCalendar) {
            TripCalendarView(trip: trip)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let data = trip.coverImageData, let image = UIImage(data: data) {
                FullScreenImageView(image: image) { updatedImage in
                    // Persist edited cover image back to the trip
                    if let jpegData = updatedImage.jpegData(compressionQuality: 0.9) {
                        trip.coverImageData = jpegData
                        try? modelContext.save()
                    }
                }
            }
        }
        .onAppear {
            // Load settings asynchronously (non-blocking)
            Task {
                settingsManager.loadSettings(from: modelContext)
            }
        }
    }
    
    // MARK: - Destination Helpers
    
    /// Apply destinations selected from `DestinationSearchView` to the current trip.
    private func applySelectedDestinationsFromSearch() {
        guard !searchSelectedDestinations.isEmpty else { return }
        
        // Respect Pro limits
        let currentCount = trip.destinations?.count ?? 0
        let maxDestinations = ProLimiter.shared.getMaxDestinationsPerTrip()
        let remainingSlots = max(0, maxDestinations - currentCount)
        guard remainingSlots > 0 else {
            searchSelectedDestinations.removeAll()
            return
        }
        
        let newSelections = Array(searchSelectedDestinations.prefix(remainingSlots))
        
        if trip.destinations == nil {
            trip.destinations = []
        }
        
        let startOrder = trip.destinations?.count ?? 0
        
        for (offset, result) in newSelections.enumerated() {
            let destination = DestinationModel(
                name: result.name,
                address: result.address,
                notes: "",
                order: startOrder + offset,
                latitude: result.coordinates?.latitude,
                longitude: result.coordinates?.longitude
            )
            modelContext.insert(destination)
            trip.destinations?.append(destination)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save destinations from search: \(error)")
        }
        
        searchSelectedDestinations.removeAll()
    }

    private func tripShareText() -> String {
        var text = "\(trip.name)\n"
        text += "\(trip.formattedDateRange)\n"
        text += "Duration: \(trip.duration) days\n\n"
        if let destinations = trip.destinations, !destinations.isEmpty {
            text += "Destinations:\n"
            for dest in destinations.sorted(by: { $0.order < $1.order }) {
                text += "• \(dest.name)\n"
            }
        }
        if !trip.notes.isEmpty {
            text += "\nNotes: \(trip.notes)"
        }
        return text
    }
}

// MARK: - Pro / AI tools row

private struct ProToolsRow: View {
    let onPlanGenerator: () -> Void
    let onOptimizer: () -> Void
    let onBudgetInsights: () -> Void
    let onCollaborate: () -> Void
    let onSmartPacking: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ProToolCard(
                    title: "tripDetail.aiPlan".localized,
                    subtitle: "tripDetail.aiPlanSubtitle".localized,
                    icon: "sparkles",
                    color: .purple,
                    action: onPlanGenerator
                )
                ProToolCard(
                    title: "tripDetail.optimize".localized,
                    subtitle: "tripDetail.optimizeSubtitle".localized,
                    icon: "wand.and.stars",
                    color: .blue,
                    action: onOptimizer
                )
                ProToolCard(
                    title: "tripDetail.budgetAI".localized,
                    subtitle: "tripDetail.budgetAISubtitle".localized,
                    icon: "chart.pie.fill",
                    color: .teal,
                    action: onBudgetInsights
                )
                ProToolCard(
                    title: "tripDetail.collaborateShort".localized,
                    subtitle: "tripDetail.collaborateSubtitle".localized,
                    icon: "person.2.fill",
                    color: .indigo,
                    action: onCollaborate
                )
                ProToolCard(
                    title: "tripDetail.smartPacking".localized,
                    subtitle: "tripDetail.smartPackingSubtitle".localized,
                    icon: "suitcase.fill",
                    color: .orange,
                    action: onSmartPacking
                )
                ProToolCard(
                    title: "tripDetail.exportShort".localized,
                    subtitle: "tripDetail.exportSubtitle".localized,
                    icon: "square.and.arrow.up",
                    color: .green,
                    action: onExport
                )
            }
            .padding(.vertical, 4)
        }
    }
}

private struct ProToolCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.currentPalette.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(themeManager.currentPalette.background)
                    .shadow(color: color.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Inline fallback Pro views

private struct InlineTripOptimizerView: View {
    @Bindable var trip: TripModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("optimizer.title".localized)
                .font(.title)
                .fontWeight(.bold)
            Text("tripDetail.optimizerHint".localized(trip.name))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

private struct InlineCollaborativeTripView: View {
    @Bindable var trip: TripModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("tripDetail.collaborativePlanning".localized)
                .font(.title)
                .fontWeight(.bold)
            Text("tripDetail.collabHint".localized(trip.name))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ShareButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .foregroundColor(.blue)
        }
    }
}

struct EmptyDestinationsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.currentPalette.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 36))
                    .foregroundColor(themeManager.currentPalette.accent)
            }
            
            VStack(spacing: 6) {
                Text("Your canvas awaits")
                    .font(.headline)
                    .foregroundColor(themeManager.currentPalette.text)
                
                Text("Tap the plus button to add places you'd love to visit.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Destination Card with Social Links
struct DestinationCardView: View {
    @Bindable var destination: DestinationModel
    let trip: TripModel
    let modelContext: ModelContext
    @EnvironmentObject var themeManager: ThemeManager
    
    // Check if text is placeholder/garbage text
    private func isPlaceholderText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else { return true }
        
        // Check for common placeholder patterns
        let placeholderPatterns = [
            "test", "placeholder", "asdasd", "lorem", "ipsum",
            "sample", "example", "dummy", "temp", "tmp", "xxx"
        ]
        
        let lowercased = trimmed.lowercased()
        
        // Check if it's mostly repetitive characters (like "asdasdasd" or "aaaaaa")
        if trimmed.count > 5 {
            // Check for repetitive patterns
            let uniqueChars = Set(trimmed.lowercased())
            if uniqueChars.count <= 2 && trimmed.count > 8 {
                return true
            }
            
            // Check for alternating patterns like "asdasd" or "asdasdasd"
            if trimmed.count > 6 {
                // Check for simple repetitive patterns (like "asdasdasd")
                let firstThree = String(trimmed.prefix(3)).lowercased()
                if trimmed.count >= 9 {
                    let secondThree = String(trimmed.dropFirst(3).prefix(3)).lowercased()
                    let thirdThree = String(trimmed.dropFirst(6).prefix(3)).lowercased()
                    
                    // If first three characters repeat, it's likely placeholder
                    if firstThree == secondThree && secondThree == thirdThree {
                        return true
                    }
                }
                
                // Check for "asd" pattern repetition
                let pattern = firstThree
                var matches = 0
                let patternLength = 3
                let totalPossible = trimmed.count / patternLength
                
                if totalPossible > 0 {
                    for i in stride(from: 0, to: trimmed.count - patternLength + 1, by: patternLength) {
                        let index = trimmed.index(trimmed.startIndex, offsetBy: i)
                        let endIndex = trimmed.index(index, offsetBy: min(patternLength, trimmed.count - i))
                        if String(trimmed[index..<endIndex]).lowercased() == pattern {
                            matches += 1
                        }
                    }
                    if Double(matches) / Double(max(1, totalPossible)) > 0.6 {
                        return true
                    }
                }
            }
            
            // Check for strings that are mostly the same few characters repeated
            if trimmed.count > 10 {
                let charFrequency = Dictionary(grouping: trimmed.lowercased(), by: { $0 })
                let sortedFreq = charFrequency.values.sorted(by: { $0.count > $1.count })
                if sortedFreq.count >= 2 {
                    let topTwoCount = sortedFreq[0].count + sortedFreq[1].count
                    if Double(topTwoCount) / Double(trimmed.count) > 0.8 {
                        return true
                    }
                }
            }
        }
        
        // Check for placeholder keywords (but allow if it's part of a real address)
        for pattern in placeholderPatterns {
            // Only flag if the pattern is a significant part of the text
            if lowercased == pattern || (lowercased.contains(pattern) && trimmed.count < 20) {
                return true
            }
        }
        
        // Check if it's all the same character repeated
        if trimmed.count > 3 && Set(trimmed.lowercased()).count == 1 {
            return true
        }
        
        // Check for "test" followed by numbers pattern (like "test 34 test 123")
        let testNumberPattern = #"^test\s*\d+(\s+test\s*\d+)*$"#
        if trimmed.range(of: testNumberPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
        
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with name and delete button
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(themeManager.currentPalette.accent)
                    .font(.title3)
                
                Text(destination.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentPalette.text)
                
                Spacer()
                
                Button(action: {
                    trip.destinations?.removeAll { $0.id == destination.id }
                    trip.lastModified = Date()
                    try? modelContext.save()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.system(size: 16))
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Address section
            if !destination.address.isEmpty && !isPlaceholderText(destination.address) {
                Divider()
                    .padding(.vertical, 8)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(themeManager.currentPalette.accent)
                        .font(.caption)
                        .padding(.top, 2)
                    
                    Text(destination.address)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Why Saved section (Roamy feature)
            if let whySaved = destination.whySaved, !whySaved.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.caption)
                        Text("tripDetail.whyISaved".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(whySaved)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            // Tips section (Roamy feature)
            if let tips = destination.tips, !tips.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("tripDetail.tipsPrep".localized)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(tips)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            // Source Links section (Roamy feature)
            if destination.savedFromSocial || destination.sourceURL != nil || destination.reviewURL != nil {
                Divider()
                    .padding(.vertical, 8)
                
                HStack(spacing: 12) {
                    if let sourceURL = destination.sourceURL, !sourceURL.isEmpty, let url = URL(string: sourceURL) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: destination.sourceURL?.contains("instagram") == true ? "camera.fill" : "music.note")
                                    .font(.caption)
                                Text("tripDetail.viewOriginalPost".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let reviewURL = destination.reviewURL, !reviewURL.isEmpty, let url = URL(string: reviewURL) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("tripDetail.reviews".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Notes section (only if valid)
            if !destination.notes.isEmpty && !isPlaceholderText(destination.notes) {
                if !destination.address.isEmpty && !isPlaceholderText(destination.address) {
                    Divider()
                        .padding(.vertical, 8)
                }
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(.orange)
                        .font(.caption)
                        .padding(.top, 2)
                    
                    Text(destination.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Social Links Section (Roamy feature)
            if destination.sourceURL != nil || destination.reviewURL != nil || destination.savedFromSocial {
                Divider()
                    .padding(.vertical, 8)
                
                HStack(spacing: 12) {
                    if destination.savedFromSocial {
                        Label("tripDetail.savedFromSocial".localized, systemImage: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    if let sourceURL = destination.sourceURL, let url = URL(string: sourceURL) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("tripDetail.originalPost".localized)
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    
                    if let reviewURL = destination.reviewURL, let url = URL(string: reviewURL) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("tripDetail.reviews".localized)
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentPalette.background)
                .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 20, x: 0, y: 8)
        )
    }
}

struct TabButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? themeManager.currentPalette.accent : Color(.systemGray5))
            .cornerRadius(18)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Full Screen Image Viewer
private struct FullScreenImageView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 1.0
    @State private var showingFilters = false
    @State private var scale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0
    @State private var isFlippedHorizontally: Bool = false
    
    private var filteredImage: UIImage {
        applyFilters(to: image)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Zoomable image view
            ZoomableImageView(
                image: filteredImage,
                rotationDegrees: rotationDegrees,
                isFlippedHorizontally: isFlippedHorizontally
            )
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Rotate button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            rotationDegrees = (rotationDegrees + 90).truncatingRemainder(dividingBy: 360)
                        }
                    } label: {
                        Image(systemName: "rotate.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Flip button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isFlippedHorizontally.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Filter toggle button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(systemName: showingFilters ? "slider.horizontal.3" : "camera.filters")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Filter controls panel
                    if showingFilters {
                        VStack(spacing: 16) {
                            // Brightness
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    Text("tripDetail.brightness".localized)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("tripDetailView.intbrightness.100".localized)
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                Slider(value: $brightness, in: -1.0...1.0)
                                    .tint(.white)
                            }
                            
                            // Contrast
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    Text("tripDetail.contrast".localized)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("tripDetailView.intcontrast.100".localized)
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                Slider(value: $contrast, in: 0.0...2.0)
                                    .tint(.white)
                            }
                            
                            // Saturation
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                    Text("tripDetail.saturation".localized)
                                        .foregroundColor(.white)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("tripDetailView.intsaturation.100".localized)
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                Slider(value: $saturation, in: 0.0...2.0)
                                    .tint(.white)
                            }
                            
                            // Reset button
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    brightness = 0.0
                                    contrast = 1.0
                                    saturation = 1.0
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("tripDetail.reset".localized)
                                }
                                .foregroundColor(.white)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20, corners: [.topLeft, .topRight])
                        .transition(.move(edge: .bottom))
                    }
                    
                    // Save changes button
                    HStack {
                        Spacer()
                        Button {
                            let finalImage = makeFinalImageForSaving()
                            onSave(finalImage)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
    }
    
    private func applyFilters(to image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func makeFinalImageForSaving() -> UIImage {
        // Start from filtered image
        let base = filteredImage
        let size = base.size
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext
            
            // Move origin to center for rotation/flip
            cg.translateBy(x: size.width / 2, y: size.height / 2)
            
            // Apply flip first (horizontal)
            if isFlippedHorizontally {
                cg.scaleBy(x: -1, y: 1)
            }
            
            // Apply rotation
            let radians = CGFloat(rotationDegrees * .pi / 180)
            cg.rotate(by: radians)
            
            // Draw image centered
            cg.translateBy(x: -size.width / 2, y: -size.height / 2)
            base.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Zoomable Image View
private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let rotationDegrees: Double
    let isFlippedHorizontally: Bool
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let imageView = context.coordinator.imageView {
            imageView.image = image
            
            // Apply rotation and flip via transform to avoid reallocating images.
            let radians = CGFloat(rotationDegrees * .pi / 180)
            var transform = CGAffineTransform.identity.rotated(by: radians)
            if isFlippedHorizontally {
                transform = transform.scaledBy(x: -1, y: 1)
            }
            imageView.transform = transform
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Center the image when zoomed
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView?.frame ?? .zero
            
            if frameToCenter.size.width < boundsSize.width {
                frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
            } else {
                frameToCenter.origin.x = 0
            }
            
            if frameToCenter.size.height < boundsSize.height {
                frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
            } else {
                frameToCenter.origin.y = 0
            }
            
            imageView?.frame = frameToCenter
        }
    }
}

// MARK: - Corner Radius Extension
private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Trip Stats Card (Detail Screen)
private struct TripStatsCard: View {
    let trip: TripModel
    @EnvironmentObject var themeManager: ThemeManager
    
    private func durationBadge(_ days: Int) -> String? {
        switch days {
        case 1: return "trips.durationOneDay".localized
        case 2...3: return "trips.durationShort".localized
        case 4...6: return "trips.durationNearlyWeek".localized
        case 7: return "trips.durationOneWeek".localized
        default:
            if days % 7 == 0 { return "trips.weeks".localized(days / 7) }
            if days > 14 { return "trips.durationLong".localized }
            return nil
        }
    }
    
    private var destinationCount: Int { trip.destinations?.count ?? 0 }
    private var statusIcon: String {
        if trip.isUpcoming { return "calendar.badge.clock" }
        if trip.isCurrent { return "airplane.departure" }
        return "checkmark.circle"
    }
    private var statusValue: String {
        if trip.isUpcoming { return "\(max(0, daysUntil))" }
        if trip.isCurrent { return "itinerary.dayN".localized(min(trip.duration, currentDay)) }
        return "trips.statusDone".localized
    }
    private var statusLabel: String {
        if trip.isUpcoming { return "trips.statusDaysUntil".localized }
        if trip.isCurrent { return "trips.statusInProgress".localized }
        return "trips.statusCompleted".localized
    }
    private var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
    }
    private var currentDay: Int {
        let day = (Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0) + 1
        return max(1, min(day, trip.duration))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                TripStatItem(icon: "clock", value: "\(trip.duration)", label: "trips.days".localized, badge: durationBadge(trip.duration))
                TripStatItem(icon: "mappin.circle", value: "\(destinationCount)", label: "destination.title".localized)
                TripStatItem(icon: statusIcon, value: statusValue, label: statusLabel)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            
            if let budget = trip.budget, budget > 0 {
                let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("trips.budget".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(SettingsManager.shared.formatAmount(totalExpenses)) / \(SettingsManager.shared.formatAmount(budget))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    ProgressView(value: min(totalExpenses, budget), total: max(budget, 0.1))
                        .tint(.green)
                        .frame(height: 6)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentPalette.background)
                .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 24, x: 0, y: 8)
        )
    }
}

private struct TripStatItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let value: String
    let label: String
    let badge: String?
    
    init(icon: String, value: String, label: String, badge: String? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.badge = badge
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 24)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentPalette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [themeManager.currentPalette.accent.opacity(0.8), themeManager.currentPalette.accent.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentPalette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
    }
}

// MARK: - Additional Overview UI
private struct TripInfoChips: View {
    let category: String
    let dateRange: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                InfoChip(icon: "calendar", text: dateRange)
                InfoChip(icon: "tag", text: category)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InfoChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(themeManager.currentPalette.accent)
                .frame(width: 14)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(themeManager.currentPalette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(themeManager.currentPalette.accent.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(themeManager.currentPalette.accent.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

private struct TripQuickLinksGrid: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    private var links: [(icon: String, title: String, index: Int)] {
        [
            ("calendar", "tripDetail.itineraryTab".localized, 1),
            ("creditcard", "tripDetail.expensesTab".localized, 2),
            ("suitcase", "tripDetail.packingTab".localized, 3)
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(links, id: \.index) { item in
                Button {
                    selectedTab = item.index
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.accent)
                            .frame(height: 20)
                        Text(item.title)
                            .font(.caption.weight(.medium))
                            .foregroundColor(themeManager.currentPalette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .frame(minHeight: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeManager.currentPalette.accent.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

private struct TripProgressCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let trip: TripModel
    
    private var isCurrent: Bool { trip.isCurrent }
    private var currentDay: Int {
        let day = (Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0) + 1
        return max(1, min(day, trip.duration))
    }
    
    var body: some View {
        Group {
            if isCurrent {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("tripDetail.tripProgress".localized)
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                        Spacer()
                        Text("tripDetail.dayLabel".localized(currentDay))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(themeManager.currentPalette.text)
                    }
                    ProgressView(value: Double(currentDay), total: Double(max(1, trip.duration)))
                        .tint(themeManager.currentPalette.accent)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentPalette.background)
                        .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 1)
                        )
                )
            } else if trip.isUpcoming {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(themeManager.currentPalette.accent)
                    Text("trips.startsInDays".localized(Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0))
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.currentPalette.background)
                        .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }
}

private struct TripPrimaryActionsRow: View {
    let onShare: () -> Void
    let onEdit: () -> Void
    let onAddDestination: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ActionItem(icon: "square.and.arrow.up", title: "tripDetail.shareAction".localized, action: onShare)
            ActionItem(icon: "pencil", title: "tripDetail.editTripAction".localized, action: onEdit)
            ActionItem(icon: "plus", title: "tripDetail.addDestinationAction".localized, action: onAddDestination)
        }
    }
}

private struct ActionItem: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.currentPalette.accent)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(themeManager.currentPalette.accent.opacity(0.08))
                            .shadow(color: themeManager.currentPalette.accent.opacity(0.1), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(themeManager.currentPalette.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(themeManager.currentPalette.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Enhancements
private struct TripOverviewCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let trip: TripModel
    
    private func durationBadge(_ days: Int) -> String? {
        switch days {
        case 1: return "trips.durationOneDay".localized
        case 2...3: return "trips.durationShort".localized
        case 4...6: return "trips.durationNearlyWeek".localized
        case 7: return "trips.durationOneWeek".localized
        default:
            if days % 7 == 0 { return "trips.weeks".localized(days / 7) }
            if days > 14 { return "trips.durationLong".localized }
            return nil
        }
    }
    
    private var statusText: String {
        if trip.isUpcoming {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
            return days <= 0 ? "trips.startsToday".localized : "trips.startsInDays".localized(days)
        } else if trip.isCurrent {
            let day = (Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0) + 1
            return "trips.dayOfTotal".localized(max(1, min(day, trip.duration)), trip.duration)
        } else {
            return "trips.completed".localized
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.currentPalette.accent)
                    .font(.caption)
                    .frame(width: 16)
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.currentPalette.accent)
                    .font(.caption)
                    .frame(width: 16)
                HStack(spacing: 6) {
                    Text("\(trip.duration) \("trips.days".localized)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.currentPalette.text)
                        .lineLimit(1)
                    if let badge = durationBadge(trip.duration) {
                        Text(badge)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(themeManager.currentPalette.accent)
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                            )
                    }
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: "tag")
                    .foregroundColor(themeManager.currentPalette.accent)
                    .font(.caption)
                    .frame(width: 16)
                Text(trip.category)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: trip.isUpcoming ? "calendar.badge.clock" : trip.isCurrent ? "airplane.departure" : "checkmark.circle")
                    .foregroundColor(themeManager.currentPalette.accent)
                    .font(.caption)
                    .frame(width: 16)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeManager.currentPalette.background)
                .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 24, x: 0, y: 8)
        )
    }
}

private struct SnapshotTilesGrid: View {
    let trip: TripModel
    @Binding var selectedTab: Int
    
    private var totalExpenses: Double { trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0 }
    private var remainingBudgetText: String {
        if let budget = trip.budget, budget > 0 {
            let remaining = max(0, budget - totalExpenses)
            return SettingsManager.shared.formatAmount(remaining)
        }
        return "—"
    }
    private var itineraryItemsCountText: String {
        let count = trip.itinerary?.count ?? 0
        return count == 1 ? "tripDetail.itemSingular".localized : "tripDetail.itemsCount".localized(count)
    }
    private var packingItemsCountText: String {
        let count = trip.packingList?.count ?? 0
        return count == 1 ? "tripDetail.itemSingular".localized : "tripDetail.itemsCount".localized(count)
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            SnapshotTile(
                icon: "creditcard",
                title: "tripDetail.expensesSection".localized,
                value: SettingsManager.shared.formatAmount(totalExpenses)
            ) {
                selectedTab = 2
            }
            
            SnapshotTile(
                icon: SettingsManager.shared.currencyIconName(filled: false),
                title: "tripDetail.remainingSection".localized,
                value: remainingBudgetText
            ) {
                selectedTab = 2
            }
            
            SnapshotTile(
                icon: "list.bullet",
                title: "tripDetail.itinerarySection".localized,
                value: itineraryItemsCountText
            ) {
                selectedTab = 1
            }
            
            SnapshotTile(
                icon: "suitcase",
                title: "tripDetail.packingSection".localized,
                value: packingItemsCountText
            ) {
                selectedTab = 3
            }
        }
    }
}

private struct SnapshotTile: View {
    @EnvironmentObject var themeManager: ThemeManager
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeManager.currentPalette.accent)
                        .frame(width: 16)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                        .lineLimit(1)
                    Spacer()
                }
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(themeManager.currentPalette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeManager.currentPalette.background)
                    .shadow(color: themeManager.currentPalette.accent.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


#Preview {
    NavigationStack {
        TripDetailView(trip: TripModel(
            name: "Summer Europe Adventure",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            notes: "First time in Europe!"
        ))
        .environmentObject(ThemeManager.shared)
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
    }
}













