//
//  NewAddActivitySheet.swift
//  Itinero
//
//  Clean, simple add activity sheet
//

import SwiftUI
import SwiftData

struct NewAddActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    let day: Int
    let date: Date
    
    @State private var title = ""
    @State private var location = ""
    @State private var time = Date()
    @State private var notes = ""
    @State private var category = "Activity"
    @State private var cost = ""
    @State private var duration = ""
    @State private var photo: UIImage?
    @State private var showingPhotoPicker = false
    @State private var isBooked = false
    
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var showingPaywall = false
    @State private var limitMessage: String?
    
    private let categories = ["Activity", "Restaurant", "Museum", "Shopping", "Hotel", "Transport", "Entertainment", "Outdoor"]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Activity name", text: $title)
                    
                    TextField("Location", text: $location)
                    
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Details") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Cost & Duration") {
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("$0.00", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("60", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Photo") {
                    if let photo = photo {
                        HStack {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 100)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button("Change") {
                                showingPhotoPicker = true
                            }
                            
                            Button("Remove", role: .destructive) {
                                self.photo = nil
                            }
                        }
                    } else {
                        Button("Add Photo") {
                            showingPhotoPicker = true
                        }
                    }
                }
                
                Section {
                    Toggle("Already Booked", isOn: $isBooked)
                }
            }
            .navigationTitle("New Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                ImagePickerView { image in
                    photo = image
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
        }
    }
    
    private func save() {
        // Check limit
        let activitiesForDay = trip.itinerary?.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? []
        let check = proLimiter.canAddActivity(currentActivityCount: activitiesForDay.count, date: date)
        
        if !check.allowed {
            limitMessage = check.reason
            showingPaywall = true
            return
        }
        
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: date)
        let calculatedDay = max(1, (dayComponents.day ?? 0) + 1)
        
        let activity = ItineraryItem(
            day: calculatedDay,
            date: date,
            title: title,
            details: notes,
            time: timeFormatter.string(from: time),
            location: location,
            order: trip.itinerary?.count ?? 0,
            isBooked: isBooked,
            bookingReference: "",
            reminderDate: nil,
            category: category,
            estimatedCost: Double(cost) ?? nil,
            estimatedDuration: Int(duration) ?? nil,
            photoData: photo?.jpegData(compressionQuality: 0.8),
            sourceURL: nil,
            travelTimeFromPrevious: nil
        )
        
        modelContext.insert(activity)
        if trip.itinerary == nil {
            trip.itinerary = []
        }
        trip.itinerary?.append(activity)
        trip.lastModified = Date()
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Save failed: \(error)")
        }
    }
}

