//
//  ItineraryView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UserNotifications

struct ItineraryView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddActivity = false
    @State private var selectedDay: Int = 1
    
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
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trip Itinerary")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(trip.duration) days • \(days.count) days planned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { showingAddActivity = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Activity")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                if days.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Invalid trip dates")
                            .font(.headline)
                        Text("Please check your trip start and end dates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Days List
                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                        let dayNumber = index + 1
                        let dayActivities = itineraryByDay[dayNumber] ?? []
                        
                        DayCardView(
                            day: dayNumber,
                            date: date,
                            activities: dayActivities,
                            trip: trip,
                            modelContext: modelContext,
                            onAddActivity: {
                                selectedDay = dayNumber
                                showingAddActivity = true
                            }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $showingAddActivity) {
            if selectedDay > 0 && selectedDay <= days.count {
                AddItineraryItemView(trip: trip, day: selectedDay, date: days[selectedDay - 1])
            } else if !days.isEmpty {
                AddItineraryItemView(trip: trip, day: 1, date: days[0])
            }
        }
    }
}

struct DayCardView: View {
    let day: Int
    let date: Date
    let activities: [ItineraryItem]
    let trip: TripModel
    let modelContext: ModelContext
    let onAddActivity: () -> Void
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Day \(day)")
                            .font(.title2)
                            .fontWeight(.bold)
                        if day == 1 {
                            Text("START")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                        if date == trip.endDate {
                            Text("END")
                                .font(.caption2)
                                .fontWeight(.bold)
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
                Button(action: onAddActivity) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
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
                // Activities List
                ForEach(activities.sorted(by: { $0.order < $1.order }), id: \.id) { activity in
                    ActivityCardView(activity: activity, modelContext: modelContext)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

struct ActivityCardView: View {
    @Bindable var activity: ItineraryItem
    let modelContext: ModelContext
    @State private var showingEdit = false
    
    var body: some View {
            HStack(alignment: .top, spacing: 12) {
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
                        }
                        
                        if !activity.time.isEmpty {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(activity.time)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        if activity.isBooked && !activity.bookingReference.isEmpty {
                            HStack {
                                Image(systemName: "ticket.fill")
                                    .font(.caption)
                                Text("Ref: \(activity.bookingReference)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        if let reminderDate = activity.reminderDate {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.caption)
                                Text("Reminder: \(reminderDate, style: .date)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    Spacer()
                    Menu {
                        Button(action: { showingEdit = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(action: {
                            activity.isBooked.toggle()
                            if let trip = findTrip(for: activity) {
                                trip.notes = trip.notes // Force change detection
                            }
                            try? modelContext.save()
                        }) {
                            Label(activity.isBooked ? "Mark Unbooked" : "Mark Booked", systemImage: activity.isBooked ? "xmark.circle" : "checkmark.circle")
                        }
                        Button(role: .destructive, action: {
                            // Find and delete from trip
                            if let trip = findTrip(for: activity) {
                                trip.itinerary?.removeAll { $0.id == activity.id }
                                trip.notes = trip.notes // Force change detection
                                try? modelContext.save()
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
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
        .sheet(isPresented: $showingEdit) {
            EditItineraryItemView(activity: activity)
        }
    }
    
    private func findTrip(for activity: ItineraryItem) -> TripModel? {
        let descriptor = FetchDescriptor<TripModel>()
        let trips = try? modelContext.fetch(descriptor)
        return trips?.first { $0.itinerary?.contains { $0.id == activity.id } ?? false }
    }
}

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
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Time", selection: $activityTime, displayedComponents: .hourAndMinute)
                    
                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Day \(day)")
                        Spacer()
                        DatePicker("Date", selection: .constant(date), displayedComponents: .date)
                            .disabled(true)
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle("New Activity")
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
        }
    }
    
    private func saveActivity() {
        let order = (trip.itinerary?.count ?? 0)
        let timeString = timeFormatter.string(from: activityTime)
        let newActivity = ItineraryItem(
            day: day,
            date: date,
            title: title,
            details: description,
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
        
        // Update a property to trigger SwiftData change detection
        trip.notes = trip.notes // Force change detection
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save activity: \(error)")
        }
        dismiss()
    }
}

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
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Details") {
                    TextField("Activity Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Time", selection: $activityTime, displayedComponents: .hourAndMinute)
                    
                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Booking Status") {
                    Toggle("Mark as Booked", isOn: $isBooked)
                    
                    if isBooked {
                        TextField("Booking Reference", text: $bookingReference)
                            .textInputAutocapitalization(.none)
                    }
                }
                
                Section("Reminder") {
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
                
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
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
        }
    }
    
    private func saveActivity() {
        activity.title = title
        activity.details = description
        activity.time = timeFormatter.string(from: activityTime)
        activity.location = location
        activity.isBooked = isBooked
        activity.bookingReference = bookingReference
        activity.reminderDate = reminderDate
        
        // Find trip for activity to trigger change detection
        let descriptor = FetchDescriptor<TripModel>()
        if let trips = try? modelContext.fetch(descriptor),
           let trip = trips.first(where: { $0.itinerary?.contains { $0.id == activity.id } ?? false }) {
            // Force change detection on trip
            trip.notes = trip.notes
            
            // Schedule notification if reminder date is set
            if let reminderDate = reminderDate, reminderDate > Date() {
                NotificationManager.shared.scheduleActivityReminder(activity: activity, tripName: trip.name)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Activity saved: \(activity.title)")
        } catch {
            print("❌ Failed to save activity: \(error)")
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

