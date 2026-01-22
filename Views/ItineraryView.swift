//
//  ItineraryView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UserNotifications
import CoreLocation

enum ItineraryViewMode {
    case calendar
    case map
    case timeline
}

struct ItineraryView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var showingAddActivity = false
    @State private var selectedDay: Int = 1
    @State private var showingPaywall = false
    @State private var limitAlertMessage: String?
    @State private var showLimitAlert = false
    @State private var viewMode: ItineraryViewMode = .timeline
    @State private var isGeneratingItinerary = false
    @State private var currentDayIndex: Int = 0
    @State private var editMode: EditMode = .inactive
    @GestureState private var dragOffset: CGFloat = 0
    
    var days: [Date] {
        var dates: [Date] = []
        var currentDate = trip.startDate
        while currentDate <= trip.endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return dates
    }
    
    var itineraryByDay: [Int: [ItineraryItem]] {
        Dictionary(grouping: trip.itinerary ?? [], by: { $0.day })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View Mode Toggle
            Picker("View Mode", selection: $viewMode) {
                Text("Timeline").tag(ItineraryViewMode.timeline)
                Text("Calendar").tag(ItineraryViewMode.calendar)
                Text("Map").tag(ItineraryViewMode.map)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color(.systemBackground))
            
            // Content based on view mode
            switch viewMode {
            case .timeline:
                timelineView
            case .calendar:
                calendarView
            case .map:
                mapView
            }
        }
        .background(Color(.systemBackground))
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
        .fullScreenCover(isPresented: $showingAddActivity) {
            if selectedDay > 0 && selectedDay <= days.count {
                AddItineraryItemView(trip: trip, day: selectedDay, date: days[selectedDay - 1])
            } else if !days.isEmpty {
                AddItineraryItemView(trip: trip, day: 1, date: days[0])
            }
        }
    }
    
    private var listView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trip Itinerary")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                        Text("\(days.count) days planned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    AnimatedButton(
                        title: "Add Activity",
                        icon: "plus.circle.fill"
                    ) {
                        // Check limit for activities on selected day
                        let activitiesForDay = trip.itinerary?.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) } ?? []
                        let check = proLimiter.canAddActivity(currentActivityCount: activitiesForDay.count, date: Date())
                        if check.allowed {
                            showingAddActivity = true
                        } else {
                            limitAlertMessage = check.reason
                            showLimitAlert = true
                        }
                    }
                }
                
                // Automated Itinerary Generation (Roamy feature)
                if let destinations = trip.destinations, !destinations.isEmpty, (trip.itinerary?.isEmpty ?? true) {
                    Button(action: {
                        generateAutomatedItinerary()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Generate Itinerary")
                                    .font(.headline)
                                Text("Create day-by-day plan from destinations")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
                
            if days.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Invalid Dates")
                        .font(.headline)
                    Text("Start date must be before end date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                // Swipeable Days View with Tab Navigation
                VStack(spacing: 0) {
                    // Day Navigation Pills
                    if days.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                                    DayNavigationPill(
                                        day: index + 1,
                                        date: date,
                                        isSelected: currentDayIndex == index
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            currentDayIndex = index
                                        }
                                        HapticManager.shared.selection()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(.ultraThinMaterial)
                    }
                    
                    // Swipeable Day Cards
                    TabView(selection: $currentDayIndex) {
                        ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                            let dayNumber = index + 1
                            let dayActivities = itineraryByDay[dayNumber] ?? []
                            
                            ScrollView {
                                VStack(spacing: 16) {
                            DayCardView(
                                day: dayNumber,
                                date: date,
                                activities: dayActivities,
                                trip: trip,
                                modelContext: modelContext,
                                onAddActivity: {
                                    HapticManager.shared.impact(.light)
                                    selectedDay = dayNumber
                                    showingAddActivity = true
                                }
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentDayIndex) { oldValue, newValue in
                    HapticManager.shared.selection()
                    }
                }
            }
        }
    }
    
    // MARK: - Automated Itinerary Generation (Roamy Feature)
    private func generateAutomatedItinerary() {
        isGeneratingItinerary = true
        
        Task {
            // Generate itinerary items - using placeholder for now
            let items: [ItineraryItem] = []
            // TODO: Implement generateAutomatedItinerary in TripOptimizer
            
            await MainActor.run {
                for item in items {
                    modelContext.insert(item)
                    if trip.itinerary == nil {
                        trip.itinerary = []
                    }
                    trip.itinerary?.append(item)
                }
                
                trip.lastModified = Date()
                
                do {
                    try modelContext.save()
                    isGeneratingItinerary = false
                } catch {
                    print("Failed to save automated itinerary: \(error)")
                    isGeneratingItinerary = false
                }
            }
        }
    }
    
    private var calendarView: some View {
        NavigationStack {
            TripCalendarDisplayView(trip: trip)
        }
    }
    
    private var mapView: some View {
        TripMapView(trip: trip)
            // Give the inner map a clear, consistent height inside the Trip Map screen
            .frame(height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
    }
    
    private var timelineView: some View {
        NewItineraryView(trip: trip)
    }
}

// MARK: - Day Navigation Pill
struct DayNavigationPill: View {
    let day: Int
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("Day \(day)")
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 11, weight: .regular))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .cornerRadius(20)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct DayCardView: View {
    let day: Int
    let date: Date
    let activities: [ItineraryItem]
    let trip: TripModel
    let modelContext: ModelContext
    let onAddActivity: () -> Void
    @State private var editMode: EditMode = .inactive
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    var dayHasPhotos: Bool {
        activities.contains { $0.photo != nil }
    }
    
    var firstActivityPhoto: UIImage? {
        activities.first(where: { $0.photo != nil })?.photo
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Day Header with Photo Background
            if let photo = firstActivityPhoto, dayHasPhotos {
                ZStack(alignment: .bottomLeading) {
                    // Large Background Photo
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.4),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Day Info Overlay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if day == 1 {
                                Text("START")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            if date == trip.endDate {
                                Text("END")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                            Spacer()
                            
                            HStack(spacing: 12) {
                                // One-Tap Route Optimization
                                if activities.count > 1 {
                                    Button(action: {
                                        optimizeDayRoute()
                                    }) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.white.opacity(0.2))
                                            .clipShape(Circle())
                                    }
                                }
                                
                                Button(action: onAddActivity) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        Text("Day \(day)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if !activities.isEmpty {
                            Text("\(activities.count) activities")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                }
            } else {
                // Day Header without Photo
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Day \(day)")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            if day == 1 {
                                Text("START")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .cornerRadius(4)
                            }
                            if date == trip.endDate {
                                Text("END")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .cornerRadius(4)
                            }
                        }
                        Text(dateFormatter.string(from: date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        // One-Tap Route Optimization (Roamy feature)
                        if activities.count > 1 {
                            Button(action: {
                                optimizeDayRoute()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                            .help("Optimize route for shortest travel time")
                        }
                        
                        Button(action: onAddActivity) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            // Activities Section
            VStack(alignment: .leading, spacing: 16) {
                if activities.isEmpty {
                    // Empty State
                    Button(action: onAddActivity) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add first activity")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                } else {
                    // Conflict Detection Warning
                    let conflicts = ItineraryConflictDetector.shared.detectConflicts(for: activities)
                    if !conflicts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Time Conflicts Detected")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            ForEach(Array(conflicts.prefix(3)), id: \.activity1.id) { conflict in
                                Text(conflict.message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if conflicts.count > 3 {
                                Text("+ \(conflicts.count - 3) more conflicts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Activities List with Drag to Reorder
                    List {
                        ForEach(activities.sorted(by: { $0.order < $1.order }), id: \.id) { activity in
                            ActivityCardView(activity: activity, modelContext: modelContext)
                                .staggered(index: activities.firstIndex(where: { $0.id == activity.id }) ?? 0, delay: 0.05)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.error()
                                        trip.itinerary?.removeAll { $0.id == activity.id }
                                        trip.lastModified = Date()
                                        try? modelContext.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onMove { source, destination in
                            // Reorder activities
                            var sortedActivities = activities.sorted(by: { $0.order < $1.order })
                            sortedActivities.move(fromOffsets: source, toOffset: destination)
                            
                            // Update order values
                            for (index, activity) in sortedActivities.enumerated() {
                                activity.order = index
                            }
                            
                            trip.lastModified = Date()
                            try? modelContext.save()
                            HapticManager.shared.success()
                        }
                        .environment(\.editMode, $editMode)
                        .listStyle(.plain)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(dayHasPhotos ? 0 : 20)
            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            .padding(.horizontal, dayHasPhotos ? 0 : 16)
            .padding(.vertical, dayHasPhotos ? 0 : 16)
        }
    }
    
    // MARK: - One-Tap Route Optimization (Roamy Feature)
    private func optimizeDayRoute() {
            guard activities.count > 1 else { return }
            
            // Get activities with locations
            var activitiesWithLocations: [(activity: ItineraryItem, location: CLLocation)] = activities.compactMap { activity in
                // Try to find destination for this activity
                let locationName = activity.location
                if !locationName.isEmpty,
                   let destination = trip.destinations?.first(where: { $0.name == locationName }),
                   let coord = destination.coordinate {
                    return (activity, CLLocation(latitude: coord.latitude, longitude: coord.longitude))
                }
                return nil
            }
            
            guard activitiesWithLocations.count > 1 else {
                HapticManager.shared.warning()
                return
            }
            
            // Optimize using nearest-neighbor algorithm
            var optimized: [ItineraryItem] = []
            var remaining = activitiesWithLocations
            var current = remaining.first
            
            while let currentItem = current, !remaining.isEmpty {
                optimized.append(currentItem.activity)
                remaining.removeAll { $0.activity.id == currentItem.activity.id }
                
                // Find nearest activity
                if !remaining.isEmpty {
                    let currentLocation = currentItem.location
                    let nearest = remaining.min { item1, item2 in
                        let dist1 = currentLocation.distance(from: item1.location)
                        let dist2 = currentLocation.distance(from: item2.location)
                        return dist1 < dist2
                    }
                    current = nearest
                } else {
                    current = nil
                }
            }
            
            // Add activities without locations at the end
            let activitiesWithoutLocations = activities.filter { activity in
                !optimized.contains { $0.id == activity.id }
            }
            optimized.append(contentsOf: activitiesWithoutLocations)
            
            // Update order values
            for (index, activity) in optimized.enumerated() {
                activity.order = index
            }
            
            trip.lastModified = Date()
            try? modelContext.save()
            
            HapticManager.shared.success()
        }
}

struct ActivityCardView: View {
        @Bindable var activity: ItineraryItem
        let modelContext: ModelContext
        @State private var showingEdit = false
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // Photo or Time Indicator
                if let photo = activity.photo {
                    VStack {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    // Time Indicator
                    VStack {
                        Circle()
                            .fill(activity.isBooked ? Color.green : Color.blue)
                            .frame(width: 12, height: 12)
                        Rectangle()
                            .fill((activity.isBooked ? Color.green : Color.blue).opacity(0.3))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: 20)
                }
                
                // Activity Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(activity.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if activity.isBooked {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                        Text("Booked")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                
                                // Category badge
                                if !activity.category.isEmpty && activity.category != "Activity" {
                                    Text(activity.category)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(categoryColor(for: activity.category))
                                        .cornerRadius(4)
                                }
                            }
                            
                            // Time and duration
                            HStack(spacing: 12) {
                                if !activity.time.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                        Text(activity.time)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                if let duration = activity.estimatedDuration {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hourglass")
                                            .font(.caption)
                                        Text(activity.estimatedDuration.map { "\($0) min" } ?? "")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                // Travel time from previous
                                if let travelTime = activity.travelTimeFromPrevious {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.right.circle")
                                            .font(.caption)
                                        Text("\(travelTime) min")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Cost estimate
                            if let cost = activity.estimatedCost {
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.caption)
                                    Text(activity.estimatedCost.map { String(format: "$%.2f", $0) } ?? "—")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.green)
                            }
                            
                            if activity.isBooked && !activity.bookingReference.isEmpty {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                        .font(.caption)
                                    Text(String(format: "Reference: %@", activity.bookingReference))
                                        .font(.caption2)
                                }
                                .foregroundColor(.blue)
                            }
                            
                            if let reminderDate = activity.reminderDate {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.caption)
                                    Text(String(format: "Reminder", reminderDate.formatted(date: .abbreviated, time: .omitted)))
                                        .font(.caption2)
                                }
                                .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { showingEdit = true }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            Button(action: {
                                let wasBooked = activity.isBooked
                                activity.isBooked.toggle()
                                if let trip = findTrip(for: activity) {
                                    trip.lastModified = Date()
                                }
                                try? modelContext.save()
                                
                                // Celebration when marking as complete
                                if !wasBooked && activity.isBooked {
                                    HapticManager.shared.success()
                                } else {
                                    HapticManager.shared.selection()
                                }
                            }) {
                                ZStack {
                                    Image(systemName: activity.isBooked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(activity.isBooked ? .green : .secondary)
                                        .font(.title3)
                                    
                                    if activity.isBooked {
                                        Circle()
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .scaleEffect(activity.isBooked ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: activity.isBooked)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !activity.location.isEmpty {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(activity.location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if !activity.details.isEmpty {
                        Text(activity.details)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .fullScreenCover(isPresented: $showingEdit) {
                EditItineraryItemView(activity: activity)
            }
        }
        
        private func categoryColor(for category: String) -> Color {
            switch category.lowercased() {
            case "restaurant", "food", "dining":
                return .orange
            case "museum", "culture", "art":
                return .purple
            case "activity", "adventure", "outdoor":
                return .blue
            case "shopping", "retail":
                return .pink
            case "hotel", "accommodation":
                return .indigo
            case "transport", "travel":
                return .gray
            default:
                return .blue
            }
        }
        
        private func findTrip(for activity: ItineraryItem) -> TripModel? {
            let descriptor = FetchDescriptor<TripModel>()
            let trips = try? modelContext.fetch(descriptor)
            return trips?.first { $0.itinerary?.contains { $0.id == activity.id } ?? false }
        }
    }

// MARK: - Add Itinerary Item View
struct AddItineraryItemView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) private var modelContext
        @Bindable var trip: TripModel
        let day: Int
        let date: Date
        
        @State private var title = ""
        @State private var description = ""
        @State private var activityTime = Date()
        @State private var location = ""
        @State private var errorMessage = ""
        @State private var showErrorAlert = false
        @State private var estimatedCost = ""
        @State private var estimatedDuration = ""
        @State private var category = "Activity"
        @State private var selectedPhoto: UIImage?
        @State private var showingImagePicker = false
        
        private let categories = ["Activity", "Restaurant", "Museum", "Shopping", "Hotel", "Transport", "Entertainment", "Outdoor"]
        
        @StateObject private var proLimiter = ProLimiter.shared
        @State private var showingPaywall = false
        @State private var limitAlertMessage: String?
        @State private var showLimitAlert = false
        
        var isFormValid: Bool {
            validateForm().isValid
        }
        
        private func validateForm() -> ValidationResult {
            let titleResult = FormValidator.validateItineraryTitle(title)
            if !titleResult.isValid {
                return titleResult
            }
            
            let locationResult = FormValidator.validateLocation(location)
            if !locationResult.isValid {
                return locationResult
            }
            
            let notesResult = FormValidator.validateNotes(description)
            if !notesResult.isValid {
                return notesResult
            }
            
            return .valid
        }
        
        private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField("Enter activity title", text: $title)
                            .textInputAutocapitalization(.words)
                            .onChange(of: title) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    title = oldValue
                                }
                            }
                        
                        DatePicker("Time", selection: $activityTime, displayedComponents: .hourAndMinute)
                        
                        TextField("Enter location", text: $location)
                            .textInputAutocapitalization(.words)
                            .onChange(of: location) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    location = oldValue
                                }
                            }
                        
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    
                    Section("Cost & Duration") {
                        HStack {
                            Text("Estimated Cost")
                            Spacer()
                            TextField("$0.00", text: $estimatedCost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Duration (minutes)")
                            Spacer()
                            TextField("60", text: $estimatedDuration)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                    
                    Section("Photo") {
                        if let photo = selectedPhoto {
                            HStack {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Button("Change Photo") {
                                    showingImagePicker = true
                                }
                                
                                Button("Remove", role: .destructive) {
                                    selectedPhoto = nil
                                }
                            }
                        } else {
                            Button("Add Photo") {
                                showingImagePicker = true
                            }
                        }
                    }
                    
                    Section {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .overlay(
                                Group {
                                    if description.isEmpty {
                                        VStack {
                                            HStack {
                                                Text("Enter description")
                                                    .foregroundColor(.secondary)
                                                    .padding(.leading, 5)
                                                    .padding(.top, 8)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            )
                    }
                    
                    Section {
                        HStack {
                            Image(systemName: "calendar")
                            Text(String(format: "Day", day))
                            Spacer()
                            DatePicker("Date", selection: .constant(date), displayedComponents: .date)
                                .disabled(true)
                                .labelsHidden()
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePickerView { image in
                        selectedPhoto = image
                    }
                }
                .navigationTitle("Add Activity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveActivity()
                        }
                        .disabled(title.isEmpty)
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
                .alert("Validation Error", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
        
        private func saveActivity() {
            // Check Pro limit for activities on this day
            let activitiesForDay = trip.itinerary?.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? []
            let limitCheck = proLimiter.canAddActivity(currentActivityCount: activitiesForDay.count, date: date)
            
            if !limitCheck.allowed {
                limitAlertMessage = limitCheck.reason
                showLimitAlert = true
                return
            }
            
            // Validate before saving
            let validation = validateForm()
            guard validation.isValid else {
                errorMessage = validation.errorMessage ?? "Please check your activity details"
                showErrorAlert = true
                return
            }
            
            let order = (trip.itinerary?.count ?? 0)
            let timeString = timeFormatter.string(from: activityTime)
            
            // Calculate day number based on date relative to trip start date
            let calendar = Calendar.current
            let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: date)
            let calculatedDay = max(1, (dayComponents.day ?? 0) + 1)
            
            let newActivity = ItineraryItem(
                day: calculatedDay,
                date: date,
                title: title,
                details: description,
                time: timeString,
                location: location,
                order: order,
                isBooked: false,
                bookingReference: "",
                reminderDate: nil,
                category: category,
                estimatedCost: Double(estimatedCost) ?? nil,
                estimatedDuration: Int(estimatedDuration) ?? nil,
                photoData: selectedPhoto?.jpegData(compressionQuality: 0.8),
                travelTimeFromPrevious: nil
            )
            modelContext.insert(newActivity)
            
            if trip.itinerary == nil {
                trip.itinerary = []
            }
            trip.itinerary?.append(newActivity)
            trip.lastModified = Date()
            
            do {
                try modelContext.save()
            } catch {
#if DEBUG
                print("Failed to save activity: \(error)")
#endif
            }
            dismiss()
        }
}

// MARK: - Edit Itinerary Item View
struct EditItineraryItemView: View {
        @Environment(\.dismiss) var dismiss
        @Environment(\.modelContext) private var modelContext
        @Bindable var activity: ItineraryItem
        
        @State private var title: String
        @State private var description: String
        @State private var activityTime: Date
        @State private var location: String
        @State private var isBooked: Bool
        @State private var bookingReference: String
        @State private var reminderDate: Date?
        @State private var estimatedCost: String
        @State private var estimatedDuration: String
        @State private var category: String
        @State private var selectedPhoto: UIImage?
        @State private var showingImagePicker = false
        
        private let categories = ["Activity", "Restaurant", "Museum", "Shopping", "Hotel", "Transport", "Entertainment", "Outdoor"]
        
        private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter
        }
        
        init(activity: ItineraryItem) {
            self.activity = activity
            _title = State(initialValue: activity.title)
            _description = State(initialValue: activity.details)
            // Parse time string to Date, or use current time as default
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let parsedTime = formatter.date(from: activity.time) ?? Date()
            _activityTime = State(initialValue: parsedTime)
            _location = State(initialValue: activity.location)
            _isBooked = State(initialValue: activity.isBooked)
            _bookingReference = State(initialValue: activity.bookingReference)
            _reminderDate = State(initialValue: activity.reminderDate)
            _estimatedCost = State(initialValue: activity.estimatedCost != nil ? String(format: "%.2f", activity.estimatedCost!) : "")
            _estimatedDuration = State(initialValue: activity.estimatedDuration != nil ? String(activity.estimatedDuration!) : "")
            _category = State(initialValue: activity.category.isEmpty ? "Activity" : activity.category)
            _selectedPhoto = State(initialValue: activity.photo)
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField("Activity Title", text: $title)
                            .textInputAutocapitalization(.words)
                            .onChange(of: title) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    title = oldValue
                                }
                            }
                        
                        DatePicker("Time", selection: $activityTime, displayedComponents: .hourAndMinute)
                        
                        TextField("Location", text: $location)
                            .textInputAutocapitalization(.words)
                            .onChange(of: location) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    location = oldValue
                                }
                            }
                        
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                    
                    Section("Cost & Duration") {
                        HStack {
                            Text("Estimated Cost")
                            Spacer()
                            TextField("$0.00", text: $estimatedCost)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Duration (minutes)")
                            Spacer()
                            TextField("60", text: $estimatedDuration)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                    
                    Section("Photo") {
                        if let photo = selectedPhoto {
                            HStack {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                
                                Spacer()
                                
                                Button("Change Photo") {
                                    showingImagePicker = true
                                }
                                
                                Button("Remove", role: .destructive) {
                                    selectedPhoto = nil
                                }
                            }
                        } else {
                            Button("Add Photo") {
                                showingImagePicker = true
                            }
                        }
                    }
                    
                    Section {
                        Toggle("Mark as Booked", isOn: $isBooked)
                        
                        if isBooked {
                            TextField("Enter booking reference", text: $bookingReference)
                                .textInputAutocapitalization(.none)
                        }
                    }
                    
                    Section {
                        Toggle("Set Reminder", isOn: Binding(
                            get: { reminderDate != nil },
                            set: { if $0 { reminderDate = Date() } else { reminderDate = nil } }
                        ))
                        
                        if reminderDate != nil {
                            DatePicker("Reminder Date", selection: Binding(
                                get: { reminderDate ?? Date() },
                                set: { reminderDate = $0 }
                            ), displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                    
                    Section {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .onChange(of: description) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    description = oldValue
                                }
                            }
                    }
                    
                    // Source URL Section (for TikTok/Instagram links)
                    if let sourceURL = activity.sourceURL, !sourceURL.isEmpty {
                        Section("Source Link") {
                            Button {
                                openURL(sourceURL)
                            } label: {
                                HStack {
                                    Image(systemName: sourceURL.contains("tiktok") ? "music.note" : sourceURL.contains("instagram") ? "camera.fill" : "link")
                                        .foregroundColor(sourceURL.contains("tiktok") ? .black : sourceURL.contains("instagram") ? Color(red: 0.8, green: 0.3, blue: 0.6) : .blue)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(sourceURL.contains("tiktok") ? "Open TikTok Video" : sourceURL.contains("instagram") ? "Open Instagram Post" : "Open Link")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(sourceURL)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("Edit Activity")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveActivity()
                        }
                        .disabled(title.isEmpty)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePickerView { image in
                        selectedPhoto = image
                    }
                }
            }
        }
        
        private func openURL(_ urlString: String) {
            guard let url = URL(string: urlString) else { return }
            UIApplication.shared.open(url)
        }
        
        private func saveActivity() {
            activity.title = title
            activity.details = description
            activity.time = timeFormatter.string(from: activityTime)
            activity.location = location
            activity.isBooked = isBooked
            activity.bookingReference = bookingReference
            activity.reminderDate = reminderDate
            // sourceURL is preserved (read-only in edit view)
            activity.category = category
            activity.estimatedCost = Double(estimatedCost) ?? nil
            activity.estimatedDuration = Int(estimatedDuration) ?? nil
            
            // Save photo
            if let photo = selectedPhoto {
                activity.photoData = photo.jpegData(compressionQuality: 0.8)
            } else {
                activity.photoData = nil
            }
            
            // Find trip for activity to trigger change detection
            let descriptor = FetchDescriptor<TripModel>()
            if let trips = try? modelContext.fetch(descriptor),
               let trip = trips.first(where: { $0.itinerary?.contains { $0.id == activity.id } ?? false }) {
                trip.lastModified = Date()
                
                // Schedule notification if reminder date is set
                if let reminderDate = reminderDate, reminderDate > Date() {
                    NotificationManager.shared.scheduleActivityReminder(activity: activity, tripName: trip.name)
                }
            }
            
            do {
                try modelContext.save()
#if DEBUG
                print("✅ Activity saved: \(activity.title)")
#endif
            } catch {
#if DEBUG
                print("❌ Failed to save activity: \(error)")
#endif
            }
            dismiss()
        }
    }

#Preview {
    ItineraryView(trip: TripModel(
        name: "Test Trip",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    ))
    .modelContainer(for: [TripModel.self, ItineraryItem.self], inMemory: true)
}

