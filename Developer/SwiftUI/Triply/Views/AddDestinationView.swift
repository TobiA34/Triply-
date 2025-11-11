//
//  AddDestinationView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct AddDestinationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    @State private var destinationName = ""
    @State private var address = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Destination Details") {
                    TextField("Destination Name", text: $destinationName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Address (Optional)", text: $address)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDestination()
                    }
                    .disabled(destinationName.isEmpty)
                }
            }
        }
    }
    
    private func saveDestination() {
        let order = trip.destinations?.count ?? 0
        let newDestination = DestinationModel(
            name: destinationName,
            address: address,
            notes: notes,
            order: order
        )
        
        modelContext.insert(newDestination)
        
        if trip.destinations == nil {
            trip.destinations = []
        }
        trip.destinations?.append(newDestination)
        
        // Force change detection
        trip.notes = trip.notes
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save destination: \(error)")
        }
        dismiss()
    }
}

#Preview {
    AddDestinationView(trip: TripModel(
        name: "Summer Europe Adventure",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    ))
    .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
}
