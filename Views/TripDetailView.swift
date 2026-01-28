//
//  TripDetailView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import PhotosUI

struct TripDetailView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditTrip = false
    @State private var showingAddDestination = false
    @State private var showingShareSheet = false
    @State private var showingImagePicker = false
    @State private var showingSocialImport = false
    @State private var showingPaywall = false
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var showingFullScreenImage = false
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var destinationSearchManager = DestinationSearchManager()
    @State private var searchSelectedDestinations: [SearchResult] = []
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Image with Parallax
                    TripHeroImageView(
                        image: trip.coverImageData != nil ? UIImage(data: trip.coverImageData!) : nil,
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
                    
                    // Tab Selector - 4 core tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            TabButton(title: "Overview", icon: "list.bullet", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            TabButton(title: "Itinerary", icon: "calendar", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            TabButton(title: "Expenses", icon: "creditcard", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            TabButton(title: "Packing", icon: "suitcase", isSelected: selectedTab == 3) {
                                selectedTab = 3
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
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        }
                        .opacity(0.1)
                        .background(Color(.systemBackground))
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

                                // Quick Links Grid (Itinerary / Expenses / Packing)
                                TripQuickLinksGrid(selectedTab: $selectedTab)
                                    .padding(.horizontal, 16)

                                // Progress Card
                                TripProgressCard(trip: trip)
                                    .padding(.horizontal, 16)

                                // Primary Actions
                                TripPrimaryActionsRow(
                                    onShare: { showingShareSheet = true },
                                    onEdit: { showingEditTrip = true },
                                    onAddDestination: { showingAddDestination = true }
                                )
                                .padding(.horizontal, 16)
                                
                                // Social Media Import Button (Pro Feature)
                                Button {
                                    let check = ProLimiter.shared.canAccessSocialMediaImport()
                                    if check.allowed {
                                        showingSocialImport = true
                                    } else {
                                        showingPaywall = true
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Import from Instagram/TikTok")
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
                                        Text("Destinations")
                                            .font(.title3.weight(.semibold))
                                        Spacer(minLength: 8)
                                        Button(action: { showingAddDestination = true }) {
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
                                                .foregroundColor(.accentColor)
                                            Text("Notes")
                                                .font(.title3.weight(.semibold))
                                            Spacer()
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                        Text(trip.notes)
                                            .font(.body)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .lineSpacing(4)
                                        }
                                        .padding(16)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.systemGray6))
                                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
                        
                        // Expenses Tab
                        if selectedTab == 2 {
                            ExpenseTrackingView(trip: trip)
                                .padding(.bottom, 100)
                        }
                        
                        // Packing List Tab
                        if selectedTab == 3 {
                            PackingListView(trip: trip)
                                .padding(.bottom, 100)
                        }
                    }
                }
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
                        Text("Back")
                    }
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
        .sheet(isPresented: $showingSocialImport) {
            SocialMediaImportView(trip: trip)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let data = trip.coverImageData, let image = UIImage(data: data) {
                FullScreenImageView(image: image)
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
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No destinations added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Destination Card with Social Links
struct DestinationCardView: View {
    @Bindable var destination: DestinationModel
    let trip: TripModel
    let modelContext: ModelContext
    
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
                    .foregroundColor(.red)
                    .font(.title3)
                
                Text(destination.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.top, 2)
                    
                    Text(destination.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        Text("Why I saved this")
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
                        Text("Tips & Prep Notes")
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
                    if let sourceURL = destination.sourceURL, !sourceURL.isEmpty {
                        Link(destination: URL(string: sourceURL)!) {
                            HStack(spacing: 6) {
                                Image(systemName: destination.sourceURL?.contains("instagram") == true ? "camera.fill" : "music.note")
                                    .font(.caption)
                                Text("View Original Post")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    if let reviewURL = destination.reviewURL, !reviewURL.isEmpty {
                        Link(destination: URL(string: reviewURL)!) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("Reviews")
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
                        Label("Saved from Social", systemImage: "heart.fill")
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
                                Text("Original Post")
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
                                Text("Reviews")
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

struct TabButton: View {
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
            .background(isSelected ? Color.blue : Color(.systemGray5))
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .ignoresSafeArea()
            
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
                }
                Spacer()
            }
        }
    }
}

// MARK: - Trip Stats Card (Detail Screen)
private struct TripStatsCard: View {
    let trip: TripModel
    
    private func durationBadge(_ days: Int) -> String? {
        switch days {
        case 1: return "One day"
        case 2...3: return "Short"
        case 4...6: return "Nearly a week"
        case 7: return "One week"
        default:
            if days % 7 == 0 { return "\(days / 7) weeks" }
            if days > 14 { return "Long trip" }
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
        if trip.isCurrent { return "Day \(min(trip.duration, currentDay))" }
        return "Done"
    }
    private var statusLabel: String {
        if trip.isUpcoming { return "days until" }
        if trip.isCurrent { return "in progress" }
        return "completed"
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
                TripStatItem(icon: "clock", value: "\(trip.duration)", label: "days", badge: durationBadge(trip.duration))
                TripStatItem(icon: "mappin.circle", value: "\(destinationCount)", label: "Destinations")
                TripStatItem(icon: statusIcon, value: statusValue, label: statusLabel)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            
            if let budget = trip.budget, budget > 0 {
                let totalExpenses = trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Budget")
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
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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

private struct TripStatItem: View {
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
                        colors: [.blue, .blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 24)
            
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
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
                                            colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)],
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
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(.primary)
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
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.primary)
                .frame(width: 14)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

private struct TripQuickLinksGrid: View {
    @Binding var selectedTab: Int
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    private var links: [(icon: String, title: String, index: Int)] {
        [
            ("calendar", "Itinerary", 1),
            ("creditcard", "Expenses", 2),
            ("suitcase", "Packing", 3)
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(links, id: \.title) { item in
                Button {
                    selectedTab = item.index
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(height: 20)
                        Text(item.title)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .frame(minHeight: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
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
        }
    }
}

private struct TripProgressCard: View {
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
                        Text("Trip Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(currentDay) / Double(max(1, trip.duration))) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    ProgressView(value: Double(currentDay), total: Double(max(1, trip.duration)))
                        .tint(.blue)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
            } else if trip.isUpcoming {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.orange)
                    Text("Starts in \(Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0) days")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
    }
}

private struct TripPrimaryActionsRow: View {
    let onShare: () -> Void
    let onEdit: () -> Void
    let onAddDestination: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ActionItem(icon: "square.and.arrow.up", title: "Share", action: onShare)
            ActionItem(icon: "pencil", title: "Edit Trip", action: onEdit)
            ActionItem(icon: "plus", title: "Add Destination", action: onAddDestination)
        }
    }
}

private struct ActionItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overview Enhancements
private struct TripOverviewCard: View {
    let trip: TripModel
    
    private func durationBadge(_ days: Int) -> String? {
        switch days {
        case 1: return "One day"
        case 2...3: return "Short"
        case 4...6: return "Nearly a week"
        case 7: return "One week"
        default:
            if days % 7 == 0 { return "\(days / 7) weeks" }
            if days > 14 { return "Long trip" }
            return nil
        }
    }
    
    private var statusText: String {
        if trip.isUpcoming {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
            return days <= 0 ? "Starts today" : "Starts in \(days) days"
        } else if trip.isCurrent {
            let day = (Calendar.current.dateComponents([.day], from: trip.startDate, to: Date()).day ?? 0) + 1
            return "Day \(max(1, min(day, trip.duration))) of \(trip.duration)"
        } else {
            return "Completed"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .frame(width: 16)
                Text(trip.formattedDateRange)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .frame(width: 16)
                HStack(spacing: 6) {
                    Text("\(trip.duration) days")
                        .font(.subheadline.weight(.semibold))
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
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
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
                    .foregroundColor(.blue)
                    .font(.caption)
                    .frame(width: 16)
                Text(trip.category)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            
            HStack(spacing: 10) {
                Image(systemName: trip.isUpcoming ? "calendar.badge.clock" : trip.isCurrent ? "airplane.departure" : "checkmark.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                    .frame(width: 16)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            SnapshotTile(
                icon: "creditcard",
                title: "Expenses",
                value: SettingsManager.shared.formatAmount(totalExpenses)
            ) {
                selectedTab = 2
            }
            
            SnapshotTile(
                icon: "dollarsign.circle",
                title: "Remaining",
                value: remainingBudgetText
            ) {
                selectedTab = 2
            }
            
            SnapshotTile(
                icon: "list.bullet",
                title: "Itinerary",
                value: "\(trip.itinerary?.count ?? 0) items"
            ) {
                selectedTab = 1
            }
            
            SnapshotTile(
                icon: "suitcase",
                title: "Packing",
                value: "\(trip.packingList?.count ?? 0) items"
            ) {
                selectedTab = 3
            }
        }
    }
}

private struct SnapshotTile: View {
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 16)
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
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
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
    }
}













