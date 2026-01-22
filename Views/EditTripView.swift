//
//  EditTripView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct EditTripView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    @State private var tripName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var selectedCategory: String
    @State private var budget: String
    
    private let categories = ["General", "Adventure", "Business", "Relaxation", "Family"]
    
    init(trip: TripModel) {
        self.trip = trip
        _tripName = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _notes = State(initialValue: trip.notes)
        _selectedCategory = State(initialValue: trip.category)
        _budget = State(initialValue: trip.budget != nil ? String(Int(trip.budget!)) : "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    TextField("Trip Name", text: $tripName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section("Budget (Optional)") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTrip()
                    }
                    .disabled(tripName.isEmpty)
                }
            }
        }
    }
    
    private func saveTrip() {
        trip.name = tripName
        trip.startDate = startDate
        trip.endDate = endDate
        trip.notes = notes
        trip.category = selectedCategory
        trip.budget = Double(budget) ?? nil
        
        // Force change detection
        trip.notes = trip.notes
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save trip: \(error)")
        }
        dismiss()
    }
}

#Preview {
    EditTripView(trip: TripModel(
        name: "Summer Europe Adventure",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
        notes: "First time in Europe!"
    ))
    .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
}
