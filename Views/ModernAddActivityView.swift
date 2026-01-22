//
//  ModernAddActivityView.swift
//  Itinero
//
//  Modern, streamlined add activity view
//

import SwiftUI
import SwiftData

struct ModernAddActivityView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    let day: Int
    let date: Date
    
    @State private var title = ""
    @State private var details = ""
    @State private var time = Date()
    @State private var location = ""
    @State private var category = "Activity"
    @State private var estimatedCost = ""
    @State private var estimatedDuration = ""
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var isBooked = false
    
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var showingPaywall = false
    @State private var limitAlertMessage: String?
    @State private var showLimitAlert = false
    
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
                        .textInputAutocapitalization(.words)
                    
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    
                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Details") {
                    TextEditor(text: $details)
                        .frame(minHeight: 100)
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
                        Text("Duration (min)")
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
                            
                            Button("Change") {
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
                    Toggle("Already Booked", isOn: $isBooked)
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
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { image in
                    selectedPhoto = image
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
        }
    }
    
    private func saveActivity() {
        // Check Pro limit
        let activitiesForDay = trip.itinerary?.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } ?? []
        let limitCheck = proLimiter.canAddActivity(currentActivityCount: activitiesForDay.count, date: date)
        
        if !limitCheck.allowed {
            limitAlertMessage = limitCheck.reason
            showLimitAlert = true
            return
        }
        
        let order = trip.itinerary?.count ?? 0
        let timeString = timeFormatter.string(from: time)
        
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.day], from: trip.startDate, to: date)
        let calculatedDay = max(1, (dayComponents.day ?? 0) + 1)
        
        let newActivity = ItineraryItem(
            day: calculatedDay,
            date: date,
            title: title,
            details: details,
            time: timeString,
            location: location,
            order: order,
            isBooked: isBooked,
            bookingReference: "",
            reminderDate: nil,
            estimatedCost: Double(estimatedCost) ?? nil,
            estimatedDuration: Int(estimatedDuration) ?? nil,
            category: category,
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
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
}

