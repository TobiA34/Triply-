//
//  AddDestinationView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

// ValidationResult is defined in Extensions/FormValidation.swift
// It's available globally, no import needed

struct AddDestinationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    @State private var refreshID = UUID()
    
    @State private var destinationName = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var selectedCountry: Country? = nil
    @State private var showingCountryPicker = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false
    
    var isFormValid: Bool {
        validateForm().isValid
    }
    
    private func validateForm() -> ValidationResult {
        let nameResult = FormValidator.validateDestinationName(destinationName)
        if !nameResult.isValid {
            return nameResult
        }
        
        let addressResult = FormValidator.validateAddress(address)
        if !addressResult.isValid {
            return addressResult
        }
        
        let notesResult = FormValidator.validateNotes(notes)
        if !notesResult.isValid {
            return notesResult
        }
        
        return .valid
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Destination Name
                     ModernTextField(
                        title: "Destination Name",
                        text: $destinationName,
                        icon: "mappin.circle.fill",
                        isRequired: true,
                        errorMessage: fieldErrors["name"]
                    )
                    
                    // Address
                    ModernTextEditor(
                        title: "Address",
                        text: $address,
                        icon: "location.fill",
                        height: 80,
                        isRequired: true,
                        errorMessage: fieldErrors["address"]
                    )
                    
                    // Country Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Country")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showingCountryPicker = true
                        }) {
                            HStack {
                                Text(selectedCountry?.localizedName ?? "Select Country")
                                    .font(.system(size: 17))
                                    .foregroundColor(selectedCountry != nil ? .primary : .secondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                    
                    // Notes
                    ModernTextEditor(
                        title: "Notes",
                        text: $notes,
                        icon: "note.text",
                        height: 100,
                        errorMessage: fieldErrors["notes"]
                    )
                    
                    // Save Button
                    ModernButton(
                        title: "Save Destination",
                        action: saveDestination,
                        icon: "checkmark.circle.fill",
                        isDisabled: !isFormValid
                    )
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(selectedCountry: $selectedCountry)
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @State private var fieldErrors: [String: String] = [:]
    
    private func saveDestination() {
        let validation = validateForm()
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Please check destination details."
            showErrorAlert = true
            return
        }
        
        var fullAddress = address
        if let country = selectedCountry {
            fullAddress = "\(address), \(country.localizedName)"
        }
        
        let destination = DestinationModel(
            name: destinationName,
            address: fullAddress,
            notes: notes
        )
        
        trip.destinations?.append(destination)
        
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
}
