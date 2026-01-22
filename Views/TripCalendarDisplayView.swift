//
//  TripCalendarDisplayView.swift
//  Itinero
//
//  Calendar view for displaying trip timeline and itinerary
//

import SwiftUI
import SwiftData

struct TripCalendarDisplayView: View {
    let trip: TripModel
    @State private var selectedDate: Date
    @State private var currentMonth: Date
    @State private var showingAddActivity = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    init(trip: TripModel) {
        self.trip = trip
        _selectedDate = State(initialValue: trip.startDate)
        _currentMonth = State(initialValue: trip.startDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Quick Stats
                quickStatsView
                
                // Quick Jump Buttons
                quickJumpButtons
                
                // Month Navigation
                monthNavigationView
                
                // Calendar Grid
                calendarGridView
                
                // Selected Date Details
                selectedDateSection
                
                // Trip Timeline Summary
                tripTimelineView
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    jumpToToday()
                } label: {
                    Image(systemName: "calendar.badge.clock")
                }
            }
        }
        .fullScreenCover(isPresented: $showingAddActivity) {
            AddItineraryItemSheet(trip: trip, selectedDate: selectedDate)
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width > 0 {
                        previousMonth()
                    } else {
                        nextMonth()
                    }
                }
        )
    }
    
    // MARK: - Quick Stats
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "calendar.badge.clock",
                label: "Days Until",
                value: "\(daysUntilTrip)",
                color: .blue
            )
            
            StatCard(
                icon: "airplane.departure",
                label: "Duration",
                value: "\(trip.duration) days",
                color: .green
            )
            
            StatCard(
                icon: "list.bullet",
                label: "Activities",
                value: "\(totalActivities)",
                color: .purple
            )
        }
    }
    
    // MARK: - Quick Jump Buttons
    private var quickJumpButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickJumpButton(
                    title: "Today",
                    icon: "calendar.badge.clock",
                    action: jumpToToday
                )
                
                QuickJumpButton(
                    title: "Start",
                    icon: "airplane.departure",
                    action: jumpToStartDate
                )
                
                QuickJumpButton(
                    title: "End",
                    icon: "airplane.arrival",
                    action: jumpToEndDate
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Month Navigation
    private var monthNavigationView: some View {
        HStack {
            Button(action: {
                HapticManager.shared.impact(.light)
                previousMonth()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.impact(.light)
                jumpToStartDate()
            }) {
                VStack(spacing: 4) {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Tap to jump to trip")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: {
                HapticManager.shared.impact(.light)
                nextMonth()
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(isNextMonthDisabled ? .gray : .blue)
            }
            .disabled(isNextMonthDisabled)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Grid
    private var calendarGridView: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 12)
            
            // Calendar Days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isInTripRange: isDateInTripRange(date),
                        isStartDate: Calendar.current.isDate(date, inSameDayAs: trip.startDate),
                        isEndDate: Calendar.current.isDate(date, inSameDayAs: trip.endDate),
                        isToday: Calendar.current.isDateInToday(date),
                        hasItinerary: hasItineraryItems(for: date),
                        activityCount: getActivityCount(for: date),
                        onTap: {
                            HapticManager.shared.impact(.light)
                            selectedDate = date
                            // Auto-scroll to selected date section
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    // Scroll will happen naturally
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Selected Date Section
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Date Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDateShort(selectedDate))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(formatDateFull(selectedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isDateInTripRange(selectedDate) {
                    Button {
                        showingAddActivity = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Activity")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
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
            }
            
            // Activities List
            if let items = getItineraryItems(for: selectedDate), !items.isEmpty {
                VStack(spacing: 12) {
                    ForEach(items.sorted(by: { $0.order < $1.order })) { item in
                        EnhancedItineraryItemCard(item: item)
                    }
                }
            } else if isDateInTripRange(selectedDate) {
                emptyDateView
            } else {
                outOfRangeView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var emptyDateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No activities scheduled")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Tap 'Add Activity' to plan your day")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddActivity = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Activity")
                }
                .font(.body)
                .fontWeight(.semibold)
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
        .padding(.vertical, 32)
    }
    
    private var outOfRangeView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Date outside trip range")
                .font(.headline)
            Text(String(format: "Select a date between %@ and %@", formatDateShort(trip.startDate), formatDateShort(trip.endDate)))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Trip Timeline Summary
    private var tripTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Timeline")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                TimelineRow(
                    icon: "airplane.departure",
                    title: "Start Date",
                    date: trip.startDate,
                    color: .green
                )
                
                TimelineRow(
                    icon: "airplane.arrival",
                    title: "End Date",
                    date: trip.endDate,
                    color: .red
                )
                
                TimelineRow(
                    icon: "calendar",
                    title: "Duration",
                    date: nil,
                    duration: trip.duration,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToSubtract = (firstDayWeekday - calendar.firstWeekday + 7) % 7
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstDayOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var isNextMonthDisabled: Bool {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return true
        }
        return nextMonth > trip.endDate
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        if let previous = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = previous
        }
    }
    
    private func nextMonth() {
        guard !isNextMonthDisabled else { return }
        let calendar = Calendar.current
        if let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = next
        }
    }
    
    private func isDateInTripRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return date >= calendar.startOfDay(for: trip.startDate) &&
               date <= calendar.startOfDay(for: trip.endDate)
    }
    
    private func hasItineraryItems(for date: Date) -> Bool {
        guard let items = trip.itinerary else { return false }
        let calendar = Calendar.current
        return items.contains { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    private func getItineraryItems(for date: Date) -> [ItineraryItem]? {
        guard let items = trip.itinerary else { return nil }
        let calendar = Calendar.current
        return items.filter { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private var daysUntilTrip: Int {
        let calendar = Calendar.current
        let now = Date()
        if trip.startDate > now {
            return calendar.dateComponents([.day], from: now, to: trip.startDate).day ?? 0
        }
        return 0
    }
    
    private var totalActivities: Int {
        trip.itinerary?.count ?? 0
    }
    
    private func getActivityCount(for date: Date) -> Int {
        guard let items = trip.itinerary else { return 0 }
        let calendar = Calendar.current
        return items.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }
    
    private func jumpToToday() {
        let today = Date()
        if isDateInTripRange(today) {
            selectedDate = today
            currentMonth = today
            HapticManager.shared.success()
        } else {
            HapticManager.shared.error()
        }
    }
    
    private func jumpToStartDate() {
        selectedDate = trip.startDate
        currentMonth = trip.startDate
        HapticManager.shared.success()
    }
    
    private func jumpToEndDate() {
        selectedDate = trip.endDate
        currentMonth = trip.endDate
        HapticManager.shared.success()
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isInTripRange: Bool
    let isStartDate: Bool
    let isEndDate: Bool
    let isToday: Bool
    let hasItinerary: Bool
    let activityCount: Int
    let onTap: () -> Void
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let dateMonth = calendar.component(.month, from: date)
        return currentMonth == dateMonth
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .frame(width: 48, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                
                VStack(spacing: 4) {
                    // Day number
                    Text("\(dayNumber)")
                        .font(.system(size: 15, weight: fontWeight))
                        .foregroundColor(textColor)
                    
                    // Activity indicators
                    if activityCount > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<min(activityCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(activityDotColor)
                                    .frame(width: 4, height: 4)
                            }
                            if activityCount > 3 {
                                Text("+\(activityCount - 3)")
                                    .font(.system(size: 8))
                                    .foregroundColor(activityDotColor)
                            }
                        }
                    } else if hasItinerary {
                        Circle()
                            .fill(activityDotColor)
                            .frame(width: 4, height: 4)
                    } else {
                        Spacer()
                            .frame(height: 4)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary.opacity(0.4)
        } else if isSelected {
            return .white
        } else if isStartDate || isEndDate {
            return .white
        } else if isToday {
            return .blue
        } else if isInTripRange {
            return .primary
        } else {
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isStartDate {
            return .green
        } else if isEndDate {
            return .orange
        } else if isToday {
            return Color.blue.opacity(0.15)
        } else if isInTripRange {
            return Color.blue.opacity(0.08)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .blue
        } else if isStartDate || isEndDate {
            return .clear
        } else {
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected || isToday {
            return 2
        }
        return 0
    }
    
    private var fontWeight: Font.Weight {
        if isSelected || isStartDate || isEndDate || isToday {
            return .bold
        }
        return .regular
    }
    
    private var activityDotColor: Color {
        if isSelected {
            return .white
        } else if isStartDate || isEndDate {
            return .white
        } else {
            return .blue
        }
    }
}

// MARK: - Enhanced Itinerary Item Card
struct EnhancedItineraryItemCard: View {
    let item: ItineraryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Time indicator with icon
            VStack(spacing: 4) {
                if !item.time.isEmpty {
                    Text(item.time)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 60, height: 60)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if !item.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text(item.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if item.isBooked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("Booked")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Quick Jump Button
struct QuickJumpButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
}

// MARK: - Add Itinerary Item Sheet
struct AddItineraryItemSheet: View {
    let trip: TripModel
    let selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var details = ""
    @State private var time = Date()
    @State private var location = ""
    @State private var showTimePicker = false
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Activity Title", text: $title)
                    TextField("Description (optional)", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Time & Location") {
                    Button {
                        showTimePicker.toggle()
                    } label: {
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(timeFormatter.string(from: time))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showTimePicker {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                    }
                    
                    TextField("Location (optional)", text: $location)
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
                    Button("Add") {
                        saveActivity()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveActivity() {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: selectedDate)
        let calculatedDay = max(1, (dayComponents.day ?? 0) + 1)
        let order = (trip.itinerary?.count ?? 0)
        let timeString = timeFormatter.string(from: time)
        
        let newActivity = ItineraryItem(
            day: calculatedDay,
            date: selectedDate,
            title: title,
            details: details,
            time: timeString,
            location: location,
            order: order,
            isBooked: false,
            bookingReference: "",
            reminderDate: nil
        )
        
        modelContext.insert(newActivity)
        
        if trip.itinerary == nil {
            trip.itinerary = []
        }
        trip.itinerary?.append(newActivity)
        trip.lastModified = Date()
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            HapticManager.shared.error()
        }
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let icon: String
    let title: String
    let date: Date?
    var duration: Int? = nil
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let date = date {
                    Text(formatDate(date))
                        .font(.body)
                        .fontWeight(.semibold)
                } else if let duration = duration {
                    Text("\(duration) days")
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

