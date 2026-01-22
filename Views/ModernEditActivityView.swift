//
//  ModernEditActivityView.swift
//  Itinero
//
//  Modern, streamlined edit activity view
//

import SwiftUI
import SwiftData

struct ModernEditActivityView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var activity: ItineraryItem
    
    @State private var title: String
    @State private var details: String
    @State private var time: Date
    @State private var location: String
    @State private var category: String
    @State private var estimatedCost: String
    @State private var estimatedDuration: String
    @State private var selectedPhoto: UIImage?
    @State private var showingImagePicker = false
    @State private var isBooked: Bool
    
    private let categories = ["Activity", "Restaurant", "Museum", "Shopping", "Hotel", "Transport", "Entertainment", "Outdoor"]
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    init(activity: ItineraryItem) {
        self.activity = activity
        _title = State(initialValue: activity.title)
        _details = State(initialValue: activity.details)
        _location = State(initialValue: activity.location)
        _category = State(initialValue: activity.category)
        _estimatedCost = State(initialValue: activity.estimatedCost.map { String(format: "%.2f", $0) } ?? "")
        _estimatedDuration = State(initialValue: activity.estimatedDuration.map { String($0) } ?? "")
        _isBooked = State(initialValue: activity.isBooked)
        
        // Parse time string to Date
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        if let timeString = activity.time.isEmpty ? nil : activity.time,
           let parsedTime = formatter.date(from: timeString) {
            _time = State(initialValue: parsedTime)
        } else {
            _time = State(initialValue: Date())
        }
        
        if let photoData = activity.photoData,
           let image = UIImage(data: photoData) {
            _selectedPhoto = State(initialValue: image)
        }
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
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { image in
                    selectedPhoto = image
                }
            }
        }
    }
    
    private func saveActivity() {
        activity.title = title
        activity.details = details
        activity.location = location
        activity.category = category
        activity.isBooked = isBooked
        activity.time = timeFormatter.string(from: time)
        activity.estimatedCost = Double(estimatedCost) ?? nil
        activity.estimatedDuration = Int(estimatedDuration) ?? nil
        activity.photoData = selectedPhoto?.jpegData(compressionQuality: 0.8)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Failed to save activity: \(error)")
        }
    }
}

