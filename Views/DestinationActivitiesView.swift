//
//  DestinationActivitiesView.swift
//  Itinero
//
//  View to show activities for a destination and add them to itinerary
//

import SwiftUI
import SwiftData
import CoreLocation
import MapKit

struct DestinationActivitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let destination: DestinationModel
    @Bindable var trip: TripModel
    
    @StateObject private var placesManager = FreePlacesManager.shared
    @State private var activities: [FreePlace] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var selectedDay: Int = 1
    @State private var selectedTime: Date = Date()
    @State private var selectedPlace: FreePlace?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapViewMode: ViewMode = .list  // Default to list since main view already has map
    @State private var currentOffset = 0
    @State private var hasMoreResults = true
    @State private var pageSize = 25  // Results per page
    @State private var selectedCategoryFilter: String = "All"
    
    enum ViewMode {
        case map, list
    }
    
    var days: [Date] {
        var dates: [Date] = []
        var currentDate = trip.startDate
        while currentDate <= trip.endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return dates
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Toggle
                Picker("View", selection: $mapViewMode) {
                    Label("Map", systemImage: "map").tag(ViewMode.map)
                    Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if mapViewMode == .map {
                    // Map View
                    mapView
                } else {
                    // List View
                    listView
                }
            }
            .navigationTitle(destination.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadActivities()
                updateMapCamera()
            }
            .onChange(of: activities) { oldValue, newValue in
                if !newValue.isEmpty {
                    Task { @MainActor in
                        updateMapCamera()
                    }
                }
            }
            .sheet(item: $selectedPlace) { place in
                AddPlaceToItinerarySheet(
                    place: place,
                    trip: trip,
                    destination: destination,
                    days: days
                )
            }
        }
    }
    
    // MARK: - Map View
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Destination marker
            if let coordinate = destination.coordinate {
                Annotation(destination.name, coordinate: coordinate) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        }
                        Text(destination.name)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }
            }
            
            // Nearby places markers
            ForEach(activities, id: \.id) { place in
                Annotation(place.name, coordinate: place.location) {
                    Button {
                        selectedPlace = place
                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 2) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 28, height: 28)
                                Image(systemName: iconForCategory(place.category))
                                    .foregroundColor(.white)
                                    .font(.caption.bold())
                            }
                            Text(place.name)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .cornerRadius(6)
                                .shadow(radius: 2)
                                .frame(maxWidth: 100)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        ScrollView {
            // Prevent accidental taps during scroll
            VStack(spacing: 20) {
                // Top padding
                Color.clear.frame(height: 8)
                // Destination Header
                VStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(destination.name)
                        .font(.title.bold())
                    
                    if !destination.address.isEmpty {
                        Text(destination.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                // Activities List
                if isLoading {
                    ProgressView()
                        .padding()
                } else if let error = errorMessage ?? placesManager.errorMessage {
                    VStack(spacing: 16) {
                        if error.lowercased().contains("rate limit") {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Rate Limit Reached")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("OpenStreetMap allows 1 request per second. Please wait a moment before trying again.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Error Loading Activities")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            errorMessage = nil
                            placesManager.errorMessage = nil
                            // Wait a bit before retrying if rate limited
                            if error.lowercased().contains("rate limit") {
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                                    await MainActor.run {
                                        loadActivities()
                                    }
                                }
                            } else {
                                loadActivities()
                            }
                        } label: {
                            Text(error.lowercased().contains("rate limit") ? "Try Again in a Moment" : "Try Again")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 40)
                } else if activities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No activities found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Using free OpenStreetMap API - no API key needed!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            loadActivities(reset: true)
                        } label: {
                            Text("Try Again")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        // Category filter pills
                        if !availableCategories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(availableCategories, id: \.self) { category in
                                        CategoryChip(
                                            title: category,
                                            isSelected: selectedCategoryFilter == category
                                        ) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedCategoryFilter = category
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(filteredActivities, id: \.id) { place in
                                ActivityPlaceCard(place: place, destination: destination) {
                                    selectedPlace = place
                                }
                            }
                            
                            // Load More Button (Pagination)
                            if hasMoreResults && !isLoading {
                                Button {
                                    loadActivities(reset: false)
                                } label: {
                                    HStack {
                                        if isLoadingMore {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        }
                                        Text(isLoadingMore ? "Loading..." : "Load More")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                                .disabled(isLoadingMore)
                            } else if isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Loading more...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.horizontal, 5)  // Reduced by 30 points total (was ~20, now 5 per side = 10 total)
                    .padding(.bottom, 8)  // Bottom padding
                }
            }
        }
        .scrollIndicators(.hidden)  // Hide scroll indicators
    }
    
    // MARK: - Helper Functions
    private func updateMapCamera() {
        guard let destinationCoord = destination.coordinate else { return }
        
        var coordinates: [CLLocationCoordinate2D] = [destinationCoord]
        coordinates.append(contentsOf: activities.map { $0.location })
        
        guard !coordinates.isEmpty else {
            cameraPosition = .region(MKCoordinateRegion(
                center: destinationCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? destinationCoord.latitude
        let maxLat = coordinates.map { $0.latitude }.max() ?? destinationCoord.latitude
        let minLon = coordinates.map { $0.longitude }.min() ?? destinationCoord.longitude
        let maxLon = coordinates.map { $0.longitude }.max() ?? destinationCoord.longitude
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
        
        let span = MKCoordinateSpan(
            latitudeDelta: min(latDelta, 0.2),
            longitudeDelta: min(lonDelta, 0.2)
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "restaurant", "food", "cafe": return "fork.knife"
        case "museum", "culture": return "building.columns"
        case "park", "outdoor": return "tree"
        case "shopping": return "bag"
        case "hotel", "accommodation": return "bed.double"
        case "transport": return "car"
        case "nightlife": return "moon.stars"
        case "theater", "entertainment": return "theatermasks"
        default: return "mappin.circle"
        }
    }
    
    // MARK: - Category Filtering
    private var availableCategories: [String] {
        let set = Set(activities.map { $0.category })
        let sorted = set.sorted()
        return ["All"] + sorted
    }
    
    private var filteredActivities: [FreePlace] {
        if selectedCategoryFilter == "All" {
            return activities
        }
        return activities.filter { $0.category == selectedCategoryFilter }
    }
    
    private func loadActivities(reset: Bool = true) {
        guard let coordinate = destination.coordinate else {
            errorMessage = "Destination location not available"
            isLoading = false
            return
        }
        
        // Validate coordinates
        guard coordinate.latitude >= -90 && coordinate.latitude <= 90,
              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
            errorMessage = "Invalid destination coordinates"
            isLoading = false
            return
        }
        
        print("📍 Loading activities for: \(destination.name)")
        print("📍 Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        
        // Reset pagination if starting fresh
        if reset {
            currentOffset = 0
            activities = []
            hasMoreResults = true
            isLoading = true
        } else {
            isLoadingMore = true
        }
        
        errorMessage = nil
        placesManager.errorMessage = nil
        
        Task {
            var allResults: [FreePlace] = []
            
            print("🔍 Starting free places search for: \(destination.name)")
            print("📍 Location: \(coordinate.latitude), \(coordinate.longitude)")
            
            // Comprehensive search with pagination support
            print("🔍 Searching for tourist attractions, museums, restaurants, and landmarks... (offset: \(currentOffset))")
            let comprehensiveResults = await placesManager.searchNearby(
                location: coordinate,
                radius: 15000,  // Increased back to 15km for better coverage
                category: nil,  // Search all categories in one query
                query: nil,
                offset: currentOffset,
                limit: pageSize
            )
            print("✅ Found \(comprehensiveResults.count) places from primary search")
            allResults.append(contentsOf: comprehensiveResults)
            
            // If we got some results but not many on first page, try a broader search
            if reset && allResults.count < 10 {
                print("🔍 Few results, trying broader search with city name...")
                let cityResults = await placesManager.searchNearby(
                    location: coordinate,
                    radius: 20000,  // Even larger radius for fallback
                    category: nil,
                    query: destination.name.isEmpty ? nil : "\(destination.name) attraction museum landmark restaurant",
                    offset: 0,
                    limit: pageSize
                )
                print("✅ Found \(cityResults.count) additional places from city search")
                allResults.append(contentsOf: cityResults)
            }
            
            // Final fallback: try Nominatim directly if still no results (only on first page)
            if reset && allResults.isEmpty {
                print("🔍 No results from Overpass, trying Nominatim directly...")
                // This will be handled by the manager's fallback logic
                let nominatimResults = await placesManager.searchNearby(
                    location: coordinate,
                    radius: 20000,
                    category: "attraction",
                    query: destination.name.isEmpty ? "attraction museum landmark" : "\(destination.name) attraction",
                    offset: 0,
                    limit: pageSize
                )
                print("✅ Found \(nominatimResults.count) places from Nominatim")
                allResults.append(contentsOf: nominatimResults)
            }
            
            // Update pagination state
            hasMoreResults = comprehensiveResults.count >= pageSize
            
            // Check for errors
            if let apiError = placesManager.errorMessage {
                print("❌ Free Places API Error: \(apiError)")
                await MainActor.run {
                    errorMessage = apiError
                    isLoading = false
                }
                return
            }
            
            print("📊 Total results before deduplication: \(allResults.count)")
            
            // Remove duplicates and calculate distances
            var uniqueResults: [(place: FreePlace, distance: Double)] = []
            var seenIds: Set<String> = []
            
            let destinationLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            for result in allResults {
                if !seenIds.contains(result.id) {
                    seenIds.insert(result.id)
                    
                    // Calculate distance from destination
                    let placeLocation = CLLocation(
                        latitude: result.location.latitude,
                        longitude: result.location.longitude
                    )
                    let distance = destinationLocation.distance(from: placeLocation)
                    
                    uniqueResults.append((place: result, distance: distance))
                }
            }
            
            print("📊 Unique results after deduplication: \(uniqueResults.count)")
            
            // Sort by distance (closest first) - optimized sorting
            uniqueResults.sort { $0.distance < $1.distance }
            
            // For pagination, append new results instead of replacing
            let newResults = uniqueResults.map { $0.place }
            
            print("✅ New results count: \(newResults.count)")
            print("📊 Total results after deduplication: \(activities.count + newResults.count)")
            
            await MainActor.run {
                if reset {
                    // Replace all results on fresh load
                    activities = newResults
                } else {
                    // Append new results for pagination
                    activities.append(contentsOf: newResults)
                }
                
                isLoading = false
                isLoadingMore = false
                
                // Update offset for next page
                if !newResults.isEmpty {
                    currentOffset += newResults.count
                }
                
                // Show error message if we have one, or if no results (only on first load)
                if let apiError = placesManager.errorMessage {
                    errorMessage = apiError
                } else if reset && activities.isEmpty {
                    errorMessage = "No places found near this location. The search may have timed out or the area may not have many points of interest. Try again or search a different area."
                } else {
                    errorMessage = nil
                    // Update map camera to show all places
                    if !activities.isEmpty {
                        updateMapCamera()
                    }
                }
            }
        }
    }
}

// MARK: - Activity Place Card
struct ActivityPlaceCard: View {
    let place: FreePlace
    let destination: DestinationModel?
    let onAdd: () -> Void
    
    init(place: FreePlace, destination: DestinationModel? = nil, onAdd: @escaping () -> Void) {
        self.place = place
        self.destination = destination
        self.onAdd = onAdd
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForCategory(place.category))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .font(.title3)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Calculate distance from destination
                if let dest = destination, let destinationCoord = dest.coordinate {
                    let destinationLoc = CLLocation(
                        latitude: destinationCoord.latitude,
                        longitude: destinationCoord.longitude
                    )
                    let placeLoc = CLLocation(
                        latitude: place.location.latitude,
                        longitude: place.location.longitude
                    )
                    let distance = destinationLoc.distance(from: placeLoc)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(formatDistance(distance))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                if !place.category.isEmpty {
                    Text(place.category)
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(place.category))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
        }
        .padding(10)  // Reduced padding to make card narrower
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    onAdd()
                }
        )
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "restaurant", "food", "cafe": return "fork.knife"
        case "museum", "culture": return "building.columns"
        case "park", "outdoor": return "tree"
        case "shopping": return "bag"
        case "hotel": return "bed.double"
        case "transport": return "car"
        default: return "mappin.circle"
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "restaurant", "food": return .orange
        case "museum", "culture": return .purple
        case "park", "outdoor": return .green
        case "shopping": return .pink
        case "hotel": return .indigo
        case "transport": return .gray
        default: return .blue
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}

// MARK: - Add Place to Itinerary Sheet
struct AddPlaceToItinerarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let place: FreePlace
    @Bindable var trip: TripModel
    let destination: DestinationModel
    let days: [Date]
    
    @State private var selectedDay: Int
    @State private var selectedTime: Date
    @State private var notes = ""
    @State private var category = "Activity"
    @State private var showingTimePicker = false
    @State private var showingDayPicker = false
    @State private var showingCategoryPicker = false
    
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var showingPaywall = false
    @State private var limitMessage: String?
    
    private let categories = ["Activity", "Restaurant", "Museum", "Shopping", "Hotel", "Transport", "Entertainment", "Outdoor"]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    init(place: FreePlace, trip: TripModel, destination: DestinationModel, days: [Date]) {
        self.place = place
        self.trip = trip
        self.destination = destination
        self.days = days
        
        // Initialize with safe values - default to day 1
        _selectedDay = State(initialValue: 1)
        
        // Set initial time to first day's date with default time (9 AM)
        if let firstDay = days.first {
            let calendar = Calendar.current
            if let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: firstDay) {
                _selectedTime = State(initialValue: defaultTime)
            } else {
                _selectedTime = State(initialValue: firstDay)
            }
        } else {
            _selectedTime = State(initialValue: Date())
        }
        
        // Auto-detect category from place
        if place.category.lowercased().contains("restaurant") || place.category.lowercased().contains("food") {
            _category = State(initialValue: "Restaurant")
        } else if place.category.lowercased().contains("museum") {
            _category = State(initialValue: "Museum")
        } else if place.category.lowercased().contains("shopping") {
            _category = State(initialValue: "Shopping")
        } else if place.category.lowercased().contains("hotel") {
            _category = State(initialValue: "Hotel")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(place.name)
                        .font(.headline)
                    
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section("Schedule") {
                    if !days.isEmpty {
                        // Use button-based day picker to prevent sheet dismissal
                        Button {
                            showingDayPicker.toggle()
                        } label: {
                            HStack {
                                Text("Day")
                                Spacer()
                                if selectedDay >= 1 && selectedDay <= days.count {
                                    let dayDate = days[selectedDay - 1]
                                    Text("Day \(selectedDay) - \(dayDate, style: .date)")
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Select Day")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if showingDayPicker {
                            Picker("Day", selection: $selectedDay) {
                                ForEach(1...days.count, id: \.self) { day in
                                    if day >= 1 && day <= days.count {
                                        let dayDate = days[day - 1]
                                        Text("Day \(day) - \(dayDate, style: .date)")
                                            .tag(day)
                                    }
                                }
                            }
                            .pickerStyle(.wheel)
                            .onChange(of: selectedDay) { oldValue, newValue in
                                // Ensure selectedDay is within valid range
                                let clampedDay = max(1, min(newValue, days.count))
                                if clampedDay != newValue {
                                    selectedDay = clampedDay
                                    return
                                }
                                // Update selectedTime to use the selected day's date (async to prevent dismissal)
                                if newValue >= 1 && newValue <= days.count {
                                    let dayDate = days[newValue - 1]
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
                                    if let newTime = calendar.date(bySettingHour: components.hour ?? 9, minute: components.minute ?? 0, second: 0, of: dayDate) {
                                        // Only update if different to avoid unnecessary state changes
                                        if !calendar.isDate(newTime, inSameDayAs: selectedTime) {
                                            Task { @MainActor in
                                                selectedTime = newTime
                                            }
                                        }
                                    }
                                }
                                // Auto-close picker after selection
                                showingDayPicker = false
                            }
                        }
                    } else {
                        Text("No days available")
                            .foregroundColor(.secondary)
                    }
                    
                    // Use button-based time picker to prevent sheet dismissal
                    Button {
                        showingTimePicker.toggle()
                    } label: {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(timeFormatter.string(from: selectedTime))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showingTimePicker {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    
                    // Use button-based category picker to prevent sheet dismissal
                    Button {
                        showingCategoryPicker.toggle()
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(category)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showingCategoryPicker {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                        .pickerStyle(.wheel)
                        .onChange(of: category) { oldValue, newValue in
                            // Auto-close picker after selection
                            showingCategoryPicker = false
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Add notes about this activity", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addToItinerary()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Limit Reached", isPresented: $showingPaywall) {
                Button("Upgrade") { }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let msg = limitMessage {
                    Text(msg)
                }
            }
            .presentationDetents([.large])  // Prevent accidental dismissal
            .presentationDragIndicator(.visible)  // Show drag indicator
        }
    }
    
    private func addToItinerary() {
        // Validate selectedDay is within bounds
        guard !days.isEmpty else {
            limitMessage = "No days available for this trip"
            showingPaywall = true
            return
        }
        
        let safeDay = max(1, min(selectedDay, days.count))
        guard safeDay >= 1 && safeDay <= days.count else {
            limitMessage = "Invalid day selected"
            showingPaywall = true
            return
        }
        
        let selectedDate = days[safeDay - 1]
        
        // Ensure selectedTime is set for the selected day
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        let finalDate: Date
        if let dateWithTime = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: selectedDate) {
            finalDate = dateWithTime
        } else {
            finalDate = selectedDate
        }
        
        // Check limit
        let activitiesForDay = trip.itinerary?.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) } ?? []
        let check = proLimiter.canAddActivity(currentActivityCount: activitiesForDay.count, date: selectedDate)
        
        if !check.allowed {
            limitMessage = check.reason
            showingPaywall = true
            return
        }
        
        let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: selectedDate)
        let calculatedDay = max(1, (dayComponents.day ?? 0) + 1)
        
        let activity = ItineraryItem(
            day: calculatedDay,
            date: finalDate,  // Use finalDate which has the correct time set
            title: place.name,
            details: notes,
            time: timeFormatter.string(from: finalDate),
            location: place.address,
            order: trip.itinerary?.count ?? 0,
            isBooked: false,
            bookingReference: "",
            reminderDate: nil,
                category: category,
                estimatedCost: nil,
                estimatedDuration: nil,
            photoData: nil,
            travelTimeFromPrevious: nil
        )
        
        modelContext.insert(activity)
        if trip.itinerary == nil {
            trip.itinerary = []
        }
        trip.itinerary?.append(activity)
        trip.lastModified = Date()
        
        Task { @MainActor in
            do {
                try modelContext.save()
                HapticManager.shared.success()
                
                // Small delay to ensure save completes
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                dismiss()
            } catch {
                print("❌ Failed to save activity: \(error)")
                // Show error to user
                limitMessage = "Failed to save activity. Please try again."
                showingPaywall = true
            }
        }
    }
}

