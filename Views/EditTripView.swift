//
//  EditTripView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct EditTripView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    private let settingsManager = SettingsManager.shared
    
    @State private var tripName: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var selectedCategory: String
    @State private var budget: String
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    private let categories = ["General", "Adventure", "Business", "Relaxation", "Family"]
    
    init(trip: TripModel) {
        self.trip = trip
        _tripName = State(initialValue: trip.name)
        _startDate = State(initialValue: trip.startDate)
        _endDate = State(initialValue: trip.endDate)
        _notes = State(initialValue: trip.notes)
        _selectedCategory = State(initialValue: trip.category)
        _budget = State(initialValue: trip.budget.map { String(Int($0)) } ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trip Name
                    ModernTextField(
                        title: "Trip Name",
                        text: $tripName,
                        icon: "airplane",
                        isRequired: true,
                        errorMessage: fieldErrors["name"]
                    )
                    .textInputAutocapitalization(.words)
                    
                    // Category
                    ModernPicker(
                        title: "Category",
                        selection: $selectedCategory,
                        options: categories.map { (value: $0, label: $0) },
                        icon: "tag.fill",
                        isRequired: true
                    )
                    
                    // Start Date
                    ModernDatePicker(
                        title: "Start Date",
                        date: $startDate,
                        icon: "calendar",
                        displayedComponents: .date
                    )
                    
                    // End Date
                    ModernDatePicker(
                        title: "End Date",
                        date: $endDate,
                        icon: "calendar",
                        displayedComponents: .date,
                        inRange: startDate...
                    )
                    
                    // Budget
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Budget (Optional)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Text(settingsManager.currentCurrency.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                            
                            TextField("0.00", text: $budget)
                                .font(.system(size: 17))
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Notes
                    ModernTextEditor(
                        title: "Notes",
                        text: $notes,
                        icon: "note.text",
                        height: 120
                    )
                    
                    // Save Button
                    ModernButton(
                        title: "Save Changes",
                        action: saveTrip,
                        icon: "checkmark.circle.fill",
                        isDisabled: !isFormValid
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @State private var fieldErrors: [String: String] = [:]
    
    var isFormValid: Bool {
        validateForm().isValid
    }
    
    private func validateForm() -> ValidationResult {
        let nameResult = FormValidator.validateTripName(tripName)
        if !nameResult.isValid {
            return nameResult
        }
        
        if endDate < startDate {
            return .invalid("End date must be after start date")
        }
        
        return .valid
    }
    
    private func saveTrip() {
        // Validate before saving
        let validation = validateForm()
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Please check your trip details"
            showErrorAlert = true
            return
        }
        
        trip.name = tripName
        trip.startDate = startDate
        trip.endDate = endDate
        trip.notes = notes
        trip.category = selectedCategory
        trip.budget = Double(budget) ?? nil
        trip.lastModified = Date()
        
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


//
//  Created on 2024
//

import SwiftUI
import SwiftData


