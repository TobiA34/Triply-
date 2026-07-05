//
//  NewItineraryView.swift
//  Itinero
//
//  Completely redesigned itinerary view - clean, intuitive, beautiful
//

import SwiftUI
import SwiftData
import CoreLocation

struct NewItineraryView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var locationManager = EnhancedLocationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedDay: Int = 1
    @State private var showingAddSheet = false
    @State private var editingActivity: ItineraryItem? = nil
    
    var days: [Date] {
        var dates: [Date] = []
        var currentDate = trip.startDate
        while currentDate <= trip.endDate {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return dates
    }
    
    var currentDayActivities: [ItineraryItem] {
        let calendar = Calendar.current
        let selectedDate = days[selectedDay - 1]
        return (trip.itinerary ?? []).filter { item in
            calendar.isDate(item.date, inSameDayAs: selectedDate)
        }.sorted(by: { $0.order < $1.order })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day Picker
            dayPicker
            
            // Content
            if trip.itinerary?.isEmpty ?? true {
                emptyState
            } else {
                activitiesList
            }
        }
        .background(themeManager.currentPalette.background)
        .sheet(isPresented: $showingAddSheet) {
            NewAddActivitySheet(trip: trip, day: selectedDay, date: days[selectedDay - 1])
        }
        .sheet(item: $editingActivity) { activity in
            NewEditActivitySheet(activity: activity)
        }
    }
    
    // MARK: - Day Picker
    private var dayPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...days.count, id: \.self) { dayNum in
                    DayButton(
                        day: dayNum,
                        date: days[dayNum - 1],
                        isSelected: selectedDay == dayNum,
                        activityCount: dayActivityCount(dayNum)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDay = dayNum
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(themeManager.currentPalette.background)
    }
    
    private func dayActivityCount(_ day: Int) -> Int {
        let calendar = Calendar.current
        let date = days[day - 1]
        return (trip.itinerary ?? []).filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.currentPalette.accent.opacity(0.2), themeManager.currentPalette.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("No Activities Yet")
                        .font(.title2.bold())
                        .foregroundColor(themeManager.currentPalette.text)
                    
                    Text("Start building your itinerary by adding activities")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            VStack(spacing: 12) {
                Button {
                    showingAddSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Your First Activity")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Activities List
    private var activitiesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Day Header
                dayHeader
                
                if currentDayActivities.isEmpty {
                    emptyDayState
                } else {
                    // Activities
                    ForEach(currentDayActivities, id: \.id) { activity in
                        ActivityRow(activity: activity) {
                            editingActivity = activity
                        } onDelete: {
                            deleteActivity(activity)
                        } onToggleBooked: {
                            toggleBooked(activity)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    private var dayHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(selectedDay)")
                        .font(.title.bold())
                        .foregroundColor(themeManager.currentPalette.text)
                    
                    Text(days[selectedDay - 1], style: .date)
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                }
                
                Spacer()
                
                if !currentDayActivities.isEmpty {
                    Text("\(currentDayActivities.count)")
                        .font(.title3.bold())
                        .foregroundColor(themeManager.currentPalette.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentPalette.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Activity", systemImage: "plus")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(themeManager.currentPalette.background)
    }
    
    private var emptyDayState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentPalette.accent.opacity(0.5))
            
            Text("No activities for this day")
                .font(.headline)
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(themeManager.currentPalette.background)
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
                print("Failed to delete: \(error)")
            }
        }
    }
    
    private func toggleBooked(_ activity: ItineraryItem) {
        activity.isBooked.toggle()
        do {
            try modelContext.save()
            HapticManager.shared.impact(.light)
        } catch {
            print("Failed to update: \(error)")
        }
    }
}

// MARK: - Day Button
struct DayButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let day: Int
    let date: Date
    let isSelected: Bool
    let activityCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.system(size: 20, weight: isSelected ? .bold : .semibold))
                
                Text(date, style: .date)
                    .font(.system(size: 10))
                
                if activityCount > 0 {
                    Circle()
                        .fill(isSelected ? Color.white : themeManager.currentPalette.accent)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundColor(isSelected ? .white : themeManager.currentPalette.text)
            .frame(width: 70)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        themeManager.currentPalette.background
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: isSelected ? themeManager.currentPalette.accent.opacity(0.3) : themeManager.currentPalette.accent.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : themeManager.currentPalette.accent.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let activity: ItineraryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    let onToggleBooked: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time/Photo Circle
                if let photo = activity.photo {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: activity.isBooked ? [.green, .green.opacity(0.8)] : [themeManager.currentPalette.accent, themeManager.currentPalette.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
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
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activity.title)
                            .font(.headline)
                            .foregroundColor(themeManager.currentPalette.text)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if activity.isBooked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                                .scaleEffect(1.1)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(themeManager.currentPalette.secondaryText.opacity(0.5))
                                .font(.title3)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggleBooked()
                            if !activity.isBooked {
                                HapticManager.shared.success()
                            } else {
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    
                    if !activity.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(activity.location)
                                .font(.subheadline)
                        }
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                    }
                    
                    // Tags
                    if activity.estimatedCost != nil || activity.estimatedDuration != nil || !activity.category.isEmpty {
                        HStack(spacing: 8) {
                            if let cost = activity.estimatedCost {
                                Tag(text: activity.estimatedCost.map { String(format: "$%.2f", $0) } ?? "—", color: .green)
                            }
                            
                            if let duration = activity.estimatedDuration {
                                Tag(text: "\(duration) min", color: themeManager.currentPalette.accent)
                            }
                            
                            if !activity.category.isEmpty && activity.category != "Activity" {
                                Tag(text: activity.category, color: categoryColor(activity.category))
                            }
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.currentPalette.background)
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
    
    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "restaurant", "food": return .orange
        case "museum", "culture": return .purple
        case "shopping": return .pink
        case "hotel": return .indigo
        case "transport": return .gray
        default: return themeManager.currentPalette.accent
        }
    }
}

// MARK: - Tag
struct Tag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(6)
    }
}

