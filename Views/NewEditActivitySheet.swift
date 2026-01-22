//
//  NewEditActivitySheet.swift
//  Itinero
//
//  Clean, simple edit activity sheet
//

import SwiftUI
import SwiftData

struct NewEditActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var activity: ItineraryItem
    
    @State private var title: String
    @State private var location: String
    @State private var time: Date
    @State private var notes: String
    @State private var category: String
    @State private var cost: String
    @State private var duration: String
    @State private var photo: UIImage?
    @State private var showingPhotoPicker = false
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
        _location = State(initialValue: activity.location)
        _notes = State(initialValue: activity.details)
        _category = State(initialValue: activity.category)
        _cost = State(initialValue: activity.estimatedCost.map { String(format: "%.2f", $0) } ?? "")
        _duration = State(initialValue: activity.estimatedDuration.map { String($0) } ?? "")
        _isBooked = State(initialValue: activity.isBooked)
        
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
            _photo = State(initialValue: image)
        }
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
                
                // Source URL Section (for TikTok/Instagram links)
                if let sourceURL = activity.sourceURL, !sourceURL.isEmpty {
                    Section("Source") {
                        Button {
                            openURL(sourceURL)
                        } label: {
                            HStack {
                                Image(systemName: sourceURL.contains("tiktok") ? "music.note" : sourceURL.contains("instagram") ? "camera.fill" : "link")
                                    .foregroundColor(sourceURL.contains("tiktok") ? .black : sourceURL.contains("instagram") ? Color(red: 0.8, green: 0.3, blue: 0.6) : .blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sourceURL.contains("tiktok") ? "Open TikTok Video" : sourceURL.contains("instagram") ? "Open Instagram Post" : "Open Link")
                                        .font(.headline)
                                    Text(sourceURL)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.secondary)
                            }
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
        }
    }
    
    private func save() {
        activity.title = title
        activity.location = location
        activity.details = notes
        activity.category = category
        activity.isBooked = isBooked
        activity.time = timeFormatter.string(from: time)
        activity.estimatedCost = Double(cost) ?? nil
        activity.estimatedDuration = Int(duration) ?? nil
        activity.photoData = photo?.jpegData(compressionQuality: 0.8)
        // sourceURL is preserved (read-only in edit view, already set on activity)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
            dismiss()
        } catch {
            print("Save failed: \(error)")
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

