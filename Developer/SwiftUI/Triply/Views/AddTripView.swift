//
//  AddTripView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UserNotifications

struct AddTripView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var searchManager = DestinationSearchManager()
    @StateObject private var settingsManager = SettingsManager.shared
    
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var selectedCategory = "General"
    @State private var budget: String = ""
    @State private var searchText = ""
    @State private var selectedDestinations: [SearchResult] = []
    @State private var showingDestinationSearch = false
    
    private let categories = ["General", "Adventure", "Business", "Relaxation", "Family"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("trips.details".localized) {
                    TextField("trips.name".localized, text: $tripName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("trips.category".localized, selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text("category.\(category.lowercased())".localized).tag(category)
                        }
                    }
                    
                    DatePicker("trips.startDate".localized, selection: $startDate, displayedComponents: .date)
                    DatePicker("trips.endDate".localized, selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                Section("destination.title".localized) {
                    Button(action: { showingDestinationSearch = true }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("destination.search".localized)
                            Spacer()
                            if !selectedDestinations.isEmpty {
                                Text("\(selectedDestinations.count)")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if !selectedDestinations.isEmpty {
                        ForEach(selectedDestinations) { destination in
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(destination.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(destination.address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    selectedDestinations.removeAll { $0.id == destination.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("trips.budget".localized) {
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $budget)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("trips.notes".localized) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("trips.new".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        saveTrip()
                    }
                    .disabled(tripName.isEmpty)
                }
            }
            .sheet(isPresented: $showingDestinationSearch) {
                DestinationSearchView(
                    searchManager: searchManager,
                    selectedDestinations: $selectedDestinations
                )
            }
        }
    }
    
    private func saveTrip() {
        guard !tripName.isEmpty else { return }
        
        let budgetValue = Double(budget) ?? nil
        let newTrip = TripModel(
            name: tripName,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            category: selectedCategory,
            budget: budgetValue
        )
        
        // Insert trip first
        modelContext.insert(newTrip)
        
        // Add selected destinations - must insert each destination separately
        if !selectedDestinations.isEmpty {
            if newTrip.destinations == nil {
                newTrip.destinations = []
            }
            
            for (index, searchResult) in selectedDestinations.enumerated() {
                let destination = DestinationModel(
                    name: searchResult.name,
                    address: searchResult.address,
                    notes: "",
                    order: index
                )
                // Insert destination into context
                modelContext.insert(destination)
                // Add to trip's destinations array
                newTrip.destinations?.append(destination)
            }
        }
        
        // Save all changes
        do {
            try modelContext.save()
            print("✅ Trip saved successfully: \(newTrip.name)")
            print("   Destinations: \(newTrip.destinations?.count ?? 0)")
            
            // Schedule default reminder (1 day before) - optional, won't block save
            Task {
                let notificationManager = NotificationManager.shared
                let authorized = await notificationManager.requestAuthorization()
                if authorized {
                    notificationManager.scheduleTripReminder(trip: newTrip, daysBefore: 1)
                }
            }
            
            dismiss()
        } catch {
            print("❌ Failed to save trip: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
}
