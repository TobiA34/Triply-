//
//  ModernItineraryView.swift
//  Itinero
//
//  Modern, intuitive itinerary view with drag-to-reorder and beautiful UI
//

import SwiftUI
import SwiftData
import CoreLocation

struct ModernItineraryView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = EnhancedLocationManager.shared
    @StateObject private var proLimiter = ProLimiter.shared
    
    @State private var selectedDayIndex: Int = 0
    @State private var showingAddActivity = false
    @State private var showingEditActivity: ItineraryItem? = nil
    @State private var draggedItem: ItineraryItem? = nil
    
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
        let calendar = Calendar.current
        return Dictionary(grouping: trip.itinerary ?? [], by: { item in
            let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: item.date)
            let dayNumber = (dayComponents.day ?? 0) + 1
            return max(1, dayNumber)
        })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Selector Header
            if days.count > 1 {
                daySelectorView
            }
            
            // Main Content
            if trip.itinerary?.isEmpty ?? true {
                emptyStateView
            } else {
                dayContentView
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddActivity) {
            ModernAddActivityView(
                trip: trip,
                day: selectedDayIndex + 1,
                date: days[selectedDayIndex]
            )
        }
        .sheet(item: $showingEditActivity) { activity in
            ModernEditActivityView(activity: activity)
        }
        .onAppear {
            // Request location if needed
            Task { @MainActor in
                if locationManager.authorizationStatus == .notDetermined {
                    await locationManager.requestAuthorization()
                }
                locationManager.startLocationUpdates()
            }
        }
    }
    
    // MARK: - Day Selector
    private var daySelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    DaySelectorButton(
                        day: index + 1,
                        date: date,
                        isSelected: selectedDayIndex == index,
                        activityCount: itineraryByDay[index + 1]?.count ?? 0
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedDayIndex = index
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
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Start Planning Your Trip")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Add activities to create your perfect itinerary")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    showingAddActivity = true
                } label: {
                    Label("Add First Activity", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Day Content
    private var dayContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                let currentDay = selectedDayIndex + 1
                let dayActivities = (itineraryByDay[currentDay] ?? []).sorted(by: { $0.order < $1.order })
                let currentDate = days[selectedDayIndex]
                
                // Day Header
                dayHeaderView(day: currentDay, date: currentDate, activityCount: dayActivities.count)
                
                if dayActivities.isEmpty {
                    emptyDayView
                } else {
                    // Activities List
                    ForEach(Array(dayActivities.enumerated()), id: \.element.id) { index, activity in
                        ModernActivityCard(
                            activity: activity,
                            onTap: {
                                showingEditActivity = activity
                            },
                            onDelete: {
                                deleteActivity(activity)
                            },
                            onToggleBooked: {
                                toggleBooked(activity)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private func dayHeaderView(day: Int, date: Date, activityCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day)")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text(date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if activityCount > 0 {
                    Text("\(activityCount) \(activityCount == 1 ? "activity" : "activities")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
            }
            
            Button {
                showingAddActivity = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Activity")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
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
        }
        .padding(.horizontal, 16)
    }
    
    private var emptyDayView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No activities for this day")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap 'Add Activity' to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func deleteActivity(_ activity: ItineraryItem) {
        withAnimation {
            trip.itinerary?.removeAll { $0.id == activity.id }
            modelContext.delete(activity)
            do {
                try modelContext.save()
                HapticManager.shared.impact(.medium)
            } catch {
                print("Failed to delete activity: \(error)")
            }
        }
    }
    
    private func toggleBooked(_ activity: ItineraryItem) {
        activity.isBooked.toggle()
        do {
            try modelContext.save()
            HapticManager.shared.impact(.light)
        } catch {
            print("Failed to update activity: \(error)")
        }
    }
}

// MARK: - Day Selector Button
struct DaySelectorButton: View {
    let day: Int
    let date: Date
    let isSelected: Bool
    let activityCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("Day \(day)")
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold))
                
                Text(date, style: .date)
                    .font(.system(size: 11))
                
                if activityCount > 0 {
                    Text("\(activityCount)")
                        .font(.caption2.bold())
                        .foregroundColor(isSelected ? .white : .blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color(.systemGray6)
                    }
                }
            )
            .cornerRadius(16)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Activity Card
struct ModernActivityCard: View {
    let activity: ItineraryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleBooked: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time/Photo Indicator
                VStack(spacing: 0) {
                    if let photo = activity.photo {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            Circle()
                                .fill(activity.isBooked ? Color.green : Color.blue)
                                .frame(width: 50, height: 50)
                            
                            if !activity.time.isEmpty {
                                Text(activity.time)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(activity.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if activity.isBooked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                    
                    if !activity.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(activity.location)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Metadata Row
                    HStack(spacing: 12) {
                        if let cost = activity.estimatedCost {
                            Label(activity.formattedCost, systemImage: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if let duration = activity.estimatedDuration {
                            Label(activity.estimatedDuration.map { "\($0) min" } ?? "—", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !activity.category.isEmpty && activity.category != "Activity" {
                            Text(activity.category)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(categoryColor(for: activity.category))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onToggleBooked()
            } label: {
                Label(activity.isBooked ? "Unbook" : "Book", systemImage: activity.isBooked ? "xmark.circle" : "checkmark.circle")
            }
            .tint(activity.isBooked ? .orange : .green)
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
}

