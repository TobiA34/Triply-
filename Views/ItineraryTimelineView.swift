//
//  ItineraryTimelineView.swift
//  Itinero
//
//  Enhanced visual timeline view with large photos - Instagram-worthy design
//

import SwiftUI
import SwiftData
import CoreLocation

struct ItineraryTimelineView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDayIndex: Int = 0
    @State private var showingAddActivity = false
    @State private var showingEditActivity: ItineraryItem? = nil
    @State private var selectedDayForAdd: Int = 1
    @State private var selectedDateForAdd: Date = Date()
    @State private var previewActivity: ItineraryItem? = nil
    
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
            // Calculate day number based on date relative to trip start date
            let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: item.date)
            let dayNumber = (dayComponents.day ?? 0) + 1
            return max(1, dayNumber) // Ensure day is at least 1
        })
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                        // Day Navigation Pills (sticky header)
                        if days.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                                        DayPillView(
                                            day: index + 1,
                                            date: date,
                                            isSelected: selectedDayIndex == index
                                        ) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedDayIndex = index
                                                proxy.scrollTo("day-\(index)", anchor: .top)
                                            }
                                            HapticManager.shared.selection()
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(
                                .ultraThinMaterial,
                                in: Rectangle()
                            )
                        }
                        
                        // Timeline Content
                        VStack(spacing: 0) {
                            // Show suggestions button if timeline is completely empty
                            if trip.itinerary?.isEmpty ?? true {
                                VStack(spacing: 20) {
                                    Image(systemName: "sparkles.rectangle.stack")
                                        .font(.system(size: 64))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.purple, .blue, .pink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .padding(.top, 40)
                                    
                                    Text("Your Timeline is Empty")
                                        .font(.title2.bold())
                                        .foregroundColor(.primary)
                                    
                                    Text("Tap the + button to add activities to your itinerary")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                                    let dayNumber = index + 1
                                    let dayActivities = itineraryByDay[dayNumber] ?? []
                                    
                                    EnhancedTimelineDayView(
                                        day: dayNumber,
                                        date: date,
                                        activities: dayActivities.sorted(by: { $0.order < $1.order }),
                                        isFirstDay: index == 0,
                                        isLastDay: index == days.count - 1,
                                        onAddActivity: {
                                            selectedDayForAdd = dayNumber
                                            selectedDateForAdd = date
                                            showingAddActivity = true
                                        },
                                        onPreviewActivity: { activity in
                                            previewActivity = activity
                                        },
                                        onEditActivity: { activity in
                                            showingEditActivity = activity
                                        },
                                        onDeleteActivity: { activity in
                                            deleteActivity(activity)
                                        },
                                        modelContext: modelContext
                                    )
                                    .id("day-\(index)")
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedDayIndex = index
                                        }
                                    }
                                }
                            }
                        }
                        }
                    }
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        HapticManager.shared.impact(.medium)
                        if !days.isEmpty {
                            selectedDayForAdd = selectedDayIndex + 1
                            selectedDateForAdd = days[selectedDayIndex]
                            showingAddActivity = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.2),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .fullScreenCover(isPresented: $showingAddActivity) {
            AddItineraryItemView(trip: trip, day: selectedDayForAdd, date: selectedDateForAdd)
        }
        // 3D-style preview when long-pressing an activity
        .sheet(item: $previewActivity) { activity in
            ActivityPreviewSheet(
                activity: activity,
                onEdit: {
                    previewActivity = nil
                    showingEditActivity = activity
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $showingEditActivity) { activity in
            NavigationStack {
                EditItineraryItemView(activity: activity)
            }
        }
    }
    
    private func deleteActivity(_ activity: ItineraryItem) {
        withAnimation {
            trip.itinerary?.removeAll { $0.id == activity.id }
            modelContext.delete(activity)
            do {
                try modelContext.save()
            } catch {
                print("Failed to delete activity: \(error)")
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Day Pill Navigation
struct DayPillView: View {
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

// MARK: - Enhanced Timeline Day View
struct EnhancedTimelineDayView: View {
    let day: Int
    let date: Date
    let activities: [ItineraryItem]
    let isFirstDay: Bool
    let isLastDay: Bool
    var onAddActivity: (() -> Void)? = nil
    /// Called when user long-presses an activity card for a quick preview.
    var onPreviewActivity: ((ItineraryItem) -> Void)? = nil
    /// Called when user taps an activity to edit it.
    var onEditActivity: ((ItineraryItem) -> Void)? = nil
    var onDeleteActivity: ((ItineraryItem) -> Void)? = nil
    var modelContext: ModelContext? = nil
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var dayHasPhotos: Bool {
        activities.contains { $0.photo != nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day Header with Large Photo Background (if available)
            if let firstActivityWithPhoto = activities.first(where: { $0.photo != nil }),
               let photo = firstActivityWithPhoto.photo {
                ZStack(alignment: .bottomLeading) {
                    // Large Background Photo
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    
                    // Gradient Overlay
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Day Info Overlay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if isFirstDay {
                                Text("START")
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                            Spacer()
                            Text("\(activities.count) activities")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Text("Day \(day)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(dateFormatter.string(from: date))
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .padding(20)
                }
            } else {
                // Day Header without Photo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Day \(day)")
                                .font(.system(size: 28, weight: .bold))
                            Text(dateFormatter.string(from: date))
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        if isFirstDay {
                            Text("START")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    if !activities.isEmpty {
                        Text("\(activities.count) activities planned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            // Activities List
            if activities.isEmpty {
                if let onAddActivity = onAddActivity {
                    EmptyDayView(
                        onAddActivity: onAddActivity
                    )
                } else {
                    EmptyDayView(
                        onAddActivity: onAddActivity ?? {}
                    )
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { activityIndex, activity in
                        EnhancedTimelineActivityView(
                            activity: activity,
                            isFirst: activityIndex == 0,
                            isLast: activityIndex == activities.count - 1,
                            showPhoto: dayHasPhotos && activity.photo != nil,
                            onPreview: {
                                onPreviewActivity?(activity)
                            },
                            onTap: {
                                onEditActivity?(activity)
                            },
                            onDelete: {
                                onDeleteActivity?(activity)
                            }
                        )
                    }
                }
                .padding(.top, dayHasPhotos ? 0 : 16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(dayHasPhotos ? 0 : 20)
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
        .padding(.horizontal, dayHasPhotos ? 0 : 16)
        .padding(.vertical, dayHasPhotos ? 0 : 16)
    }
}

// MARK: - Enhanced Timeline Activity View
struct EnhancedTimelineActivityView: View {
    let activity: ItineraryItem
    let isFirst: Bool
    let isLast: Bool
    let showPhoto: Bool
    /// Long-press preview handler.
    var onPreview: (() -> Void)? = nil
    /// Tap handler (used for editing).
    var onTap: (() -> Void)? = nil
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Full-width Photo Card (if photo exists and showPhoto is true)
            if showPhoto, let photo = activity.photo {
                Button(action: {
                    onTap?()
                }) {
                    ZStack(alignment: .bottomLeading) {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 320)
                            .frame(maxWidth: .infinity)
                            .clipped()
                        
                        // Gradient Overlay for Text
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Activity Info Overlay
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if !activity.location.isEmpty {
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.caption)
                                            Text(activity.location)
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    // Source URL Link (for TikTok/Instagram)
                                    if let sourceURL = activity.sourceURL, !sourceURL.isEmpty {
                                        Button {
                                            openURL(sourceURL)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: sourceURL.contains("tiktok") ? "music.note" : sourceURL.contains("instagram") ? "camera.fill" : "link")
                                                    .font(.caption)
                                                Text(sourceURL.contains("tiktok") ? "Open TikTok" : sourceURL.contains("instagram") ? "Open Instagram" : "Open Link")
                                                    .font(.caption.bold())
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    if !activity.time.isEmpty {
                                        Text(activity.time)
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                    }
                                    
                                    if activity.isBooked {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Booked")
                                                .font(.caption.bold())
                                        }
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // Cost and Duration
                            HStack(spacing: 16) {
                                if let cost = activity.estimatedCost {
                                    HStack(spacing: 6) {
                                        Image(systemName: "dollarsign.circle.fill")
                                        Text(activity.formattedCost)
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.3))
                                    .cornerRadius(8)
                                }
                                
                                if let duration = activity.estimatedDuration {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                        Text(activity.estimatedDuration.map { "\($0) min" } ?? "—")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                
                                if !activity.category.isEmpty && activity.category != "Activity" {
                                    Text(activity.category)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.3))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .buttonStyle(.plain)
                .onLongPressGesture {
                    onPreview?()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } else {
                // Compact Activity Card (no photo or showPhoto is false)
                Button(action: {
                    onTap?()
                }) {
                    HStack(alignment: .top, spacing: 16) {
                    // Timeline Indicator
                    VStack(spacing: 0) {
                        if !isFirst {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 3)
                                .frame(height: 20)
                        }
                        
                        ZStack {
                            Circle()
                                .fill(activity.isBooked ? Color.green : Color.blue)
                                .frame(width: 20, height: 20)
                            
                            if activity.isBooked {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        if !isLast {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 3)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 24)
                    
                    // Activity Content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(activity.title)
                                    .font(.headline)
                                
                                if !activity.location.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.caption)
                                        Text(activity.location)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                if !activity.time.isEmpty {
                                    Text(activity.time)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                
                                if activity.isBooked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                        }
                        
                        // Cost, Duration, Category
                        HStack(spacing: 12) {
                            if let cost = activity.estimatedCost {
                                Label(activity.formattedCost, systemImage: "dollarsign.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            if let duration = activity.estimatedDuration {
                                Label(activity.estimatedDuration.map { "\($0) min" } ?? "—", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !activity.category.isEmpty && activity.category != "Activity" {
                                Text(activity.category)
                                    .font(.caption2.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                        
                        if !activity.details.isEmpty {
                            Text(activity.details)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        
                        // Source URL Link (TikTok/Instagram)
                        if let sourceURL = activity.sourceURL, !sourceURL.isEmpty {
                            Button {
                                openURL(sourceURL)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: sourceURL.contains("tiktok") ? "music.note" : sourceURL.contains("instagram") ? "camera.fill" : "link")
                                        .foregroundColor(sourceURL.contains("tiktok") ? .black : sourceURL.contains("instagram") ? Color(red: 0.8, green: 0.3, blue: 0.6) : .blue)
                                        .font(.caption)
                                    Text(sourceURL.contains("tiktok") ? "Open TikTok Video" : sourceURL.contains("instagram") ? "Open Instagram Post" : "Open Link")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.top, 4)
                        }
                    }
                    }
                    .padding(16)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .onLongPressGesture {
                    onPreview?()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, showPhoto ? 0 : 16)
        .padding(.vertical, showPhoto ? 0 : 8)
    }
}

// MARK: - Activity Preview Sheet (3D-style popup)

struct ActivityPreviewSheet: View {
    let activity: ItineraryItem
    let onEdit: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(activity.title)
                                .font(.title2.bold())
                            
                            if !activity.location.isEmpty {
                                Label(activity.location, systemImage: "mappin.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if !activity.details.isEmpty {
                        Text(activity.details)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 12) {
                        if let cost = activity.estimatedCost {
                            Label(activity.formattedCost, systemImage: "dollarsign.circle.fill")
                                .foregroundColor(.green)
                        }
                        if let duration = activity.estimatedDuration {
                            Label(activity.estimatedDuration.map { "\($0) min" } ?? "—", systemImage: "clock")
                                .foregroundColor(.secondary)
                        }
                        if !activity.category.isEmpty && activity.category != "Activity" {
                            Text(activity.category)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 24)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Empty Day View
struct EmptyDayView: View {
    let onAddActivity: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No activities planned")
                .font(.headline)
            
            Text("Tap the button below to add activities to this day")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onAddActivity) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Activity")
                        .fontWeight(.semibold)
                }
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
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    ItineraryTimelineView(trip: TripModel(
        name: "Paris Trip",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    ))
    .modelContainer(for: [TripModel.self, ItineraryItem.self], inMemory: true)
}
 
