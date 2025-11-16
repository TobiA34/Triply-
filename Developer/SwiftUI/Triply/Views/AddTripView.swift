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
    
    // Basic Info
    @State private var tripName = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var selectedCategory = "General"
    
    // Budget
    @State private var budget: String = ""
    @State private var accommodationBudget: String = ""
    @State private var foodBudget: String = ""
    @State private var activitiesBudget: String = ""
    @State private var transportationBudget: String = ""
    
    // Destinations
    @State private var selectedDestinations: [SearchResult] = []
    @State private var showingDestinationSearch = false
    
    // Additional Fields
    @State private var travelCompanions: Int = 1
    @State private var priority: TripPriority = .medium
    @State private var travelMode: TravelMode = .flight
    @State private var accommodationType: AccommodationType = .hotel
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var hasInsurance = false
    @State private var reminderDaysBefore: Int = 1
    @State private var weatherPreference: WeatherPreference = .any
    
    // UI State
    @State private var expandedSections: Set<String> = ["basic", "destinations"]
    @State private var showingCategoryPicker = false
    @State private var showingPriorityPicker = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showTemplates = true  // Show templates by default
    @State private var showTips = true  // Show tips by default
    
    private let categories = ["General", "Adventure", "Business", "Relaxation", "Family", "Romantic", "Solo", "Group"]
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var totalBudget: Double {
        let main = Double(budget) ?? 0
        let acc = Double(accommodationBudget) ?? 0
        let food = Double(foodBudget) ?? 0
        let act = Double(activitiesBudget) ?? 0
        let trans = Double(transportationBudget) ?? 0
        return main + acc + food + act + trans
    }
    
    var isFormValid: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty &&
        endDate >= startDate &&
        duration >= 0
    }
    
    var formCompletionPercentage: Int {
        var completed = 0
        let total = 8
        
        if !tripName.isEmpty { completed += 1 }
        if selectedCategory != "General" { completed += 1 }
        if !selectedDestinations.isEmpty { completed += 1 }
        if totalBudget > 0 || !budget.isEmpty { completed += 1 }
        if travelCompanions > 1 { completed += 1 }
        if !notes.isEmpty { completed += 1 }
        if !tags.isEmpty { completed += 1 }
        if hasInsurance || reminderDaysBefore > 0 { completed += 1 }
        
        return Int((Double(completed) / Double(total)) * 100)
    }
    
    var body: some View {
        Form {
            // Header Section (inside Form)
            Section {
                headerSection
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Quick Templates
            quickTemplatesSection
            
            // Tips & Suggestions
            tipsSection
            
            // Basic Information
            basicInfoSection
            
            // Destinations
            destinationsSection
            
            // Budget Breakdown
            budgetSection
            
            // Travel Details
            travelDetailsSection
            
            // Additional Options
            additionalOptionsSection
            
            // Notes
            notesSection
            
            // Quick Stats Preview
            statsPreviewSection
        }
        .formStyle(.grouped)
        .navigationTitle("trips.new".localized)
        .navigationBarTitleDisplayMode(.large)
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
                .disabled(!isFormValid || isSaving)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingDestinationSearch) {
            DestinationSearchView(
                searchManager: searchManager,
                selectedDestinations: $selectedDestinations
            )
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Trip created successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Quick Templates Section
    private var quickTemplatesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Quick Templates", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { showTemplates.toggle() }) {
                        Image(systemName: showTemplates ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if showTemplates {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tap a template to quickly fill in common trip details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                TemplateCard(
                                    icon: "beach.umbrella.fill",
                                    title: "Beach Vacation",
                                    color: .blue,
                                    action: {
                                        applyTemplate(.beach)
                                    }
                                )
                                TemplateCard(
                                    icon: "mountain.2.fill",
                                    title: "Mountain Adventure",
                                    color: .green,
                                    action: {
                                        applyTemplate(.mountain)
                                    }
                                )
                                TemplateCard(
                                    icon: "building.2.fill",
                                    title: "City Break",
                                    color: .purple,
                                    action: {
                                        applyTemplate(.city)
                                    }
                                )
                                TemplateCard(
                                    icon: "airplane",
                                    title: "Business Trip",
                                    color: .orange,
                                    action: {
                                        applyTemplate(.business)
                                    }
                                )
                                TemplateCard(
                                    icon: "heart.fill",
                                    title: "Romantic Getaway",
                                    color: .pink,
                                    action: {
                                        applyTemplate(.romantic)
                                    }
                                )
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Get Started")
                .font(.headline)
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Tips & Suggestions", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { showTips.toggle() }) {
                        Image(systemName: showTips ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                if showTips {
                    VStack(alignment: .leading, spacing: 10) {
                        TipRow(
                            icon: "star.fill",
                            text: getCategoryTip(),
                            color: .orange
                        )
                        
                        if !selectedDestinations.isEmpty {
                            TipRow(
                                icon: "mappin.circle.fill",
                                text: "Add multiple destinations to create a multi-city trip",
                                color: .blue
                            )
                        }
                        
                        if totalBudget > 0 {
                            TipRow(
                                icon: "dollarsign.circle.fill",
                                text: "Break down your budget by category for better tracking",
                                color: .green
                            )
                        }
                        
                        if duration > 7 {
                            TipRow(
                                icon: "calendar.badge.clock",
                                text: "For longer trips, consider adding an itinerary to stay organized",
                                color: .purple
                            )
                        }
                        
                        // Always show a helpful tip
                        if selectedDestinations.isEmpty && totalBudget == 0 {
                            TipRow(
                                icon: "arrow.right.circle.fill",
                                text: "Start by adding a destination or setting a budget to get personalized suggestions",
                                color: .blue
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Helpful Tips")
                .font(.headline)
        }
    }
    
    // MARK: - Stats Preview Section
    private var statsPreviewSection: some View {
        Section {
            VStack(spacing: 12) {
                Text("Trip Summary")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isFormValid {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            icon: "calendar",
                            label: "Duration",
                            value: "\(duration) \(duration == 1 ? "day" : "days")",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "person.2.fill",
                            label: "Travelers",
                            value: "\(travelCompanions)",
                            color: .purple
                        )
                        
                        if totalBudget > 0 {
                            StatCard(
                                icon: "dollarsign.circle.fill",
                                label: "Budget",
                                value: "\(settingsManager.currentCurrency.symbol)\(String(format: "%.0f", totalBudget))",
                                color: .green
                            )
                        }
                        
                        StatCard(
                            icon: "mappin.circle.fill",
                            label: "Destinations",
                            value: "\(selectedDestinations.count)",
                            color: .orange
                        )
                    }
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("Complete the form to see trip summary")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Preview")
                .font(.headline)
        }
    }
    
    // MARK: - Helper Functions
    private func getCategoryTip() -> String {
        switch selectedCategory {
        case "Adventure":
            return "Pack light and include adventure gear. Consider travel insurance for activities."
        case "Business":
            return "Keep receipts for expenses. Plan meetings in advance and check time zones."
        case "Relaxation":
            return "Book spa appointments early. Pack comfortable clothing and don't over-schedule."
        case "Family":
            return "Plan kid-friendly activities. Pack snacks and entertainment for travel time."
        case "Romantic":
            return "Make dinner reservations in advance. Consider special experiences or surprises."
        case "Solo":
            return "Stay connected with family. Share your itinerary and check in regularly."
        default:
            return "Add destinations and set a budget to get personalized AI suggestions for your trip."
        }
    }
    
    private func applyTemplate(_ template: TripTemplate) {
        withAnimation {
            switch template {
            case .beach:
                tripName = "Beach Vacation"
                selectedCategory = "Relaxation"
                travelMode = .flight
                accommodationType = .resort
                weatherPreference = .sunny
                tags = ["beach", "relaxation", "sun"]
                reminderDaysBefore = 3
            case .mountain:
                tripName = "Mountain Adventure"
                selectedCategory = "Adventure"
                travelMode = .car
                accommodationType = .camping
                weatherPreference = .cold
                tags = ["hiking", "nature", "adventure"]
                reminderDaysBefore = 5
            case .city:
                tripName = "City Break"
                selectedCategory = "General"
                travelMode = .flight
                accommodationType = .hotel
                weatherPreference = .moderate
                tags = ["city", "culture", "sightseeing"]
                reminderDaysBefore = 2
            case .business:
                tripName = "Business Trip"
                selectedCategory = "Business"
                travelMode = .flight
                accommodationType = .hotel
                weatherPreference = .any
                tags = ["business", "work"]
                reminderDaysBefore = 1
            case .romantic:
                tripName = "Romantic Getaway"
                selectedCategory = "Romantic"
                travelMode = .flight
                accommodationType = .resort
                weatherPreference = .sunny
                tags = ["romantic", "couple"]
                travelCompanions = 2
                reminderDaysBefore = 7
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Trip Name or Welcome Message
            VStack(spacing: 4) {
                if !tripName.isEmpty {
                    Text(tripName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                } else {
                    VStack(spacing: 4) {
                        Text("New Adventure Awaits")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Fill in the details below to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Stats Row
            HStack(spacing: 12) {
                if duration > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("\(duration) \(duration == 1 ? "day" : "days")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Form Completion Indicator
                HStack(spacing: 6) {
                    Image(systemName: formCompletionPercentage == 100 ? "checkmark.circle.fill" : "circle.fill")
                        .font(.caption)
                        .foregroundColor(formCompletionPercentage == 100 ? .green : (formCompletionPercentage > 50 ? .orange : .secondary))
                    Text("\(formCompletionPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if !selectedDestinations.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                        Text("\(selectedDestinations.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section {
            VStack(spacing: 20) {
                // Trip Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Trip Name", systemImage: "text.book.closed.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., Summer Europe Adventure", text: $tripName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.words)
                    
                    if tripName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                            Text("Give your trip a memorable name")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Label("Category", systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text("category.\(category.lowercased())".localized)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("category.\(selectedCategory.lowercased())".localized)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Dates
                VStack(alignment: .leading, spacing: 12) {
                    Label("Travel Dates", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                    // Date validation warning
                    if endDate < startDate {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("End date must be after start date")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Basic Information")
                .font(.headline)
        }
    }
    
    // MARK: - Destinations Section
    private var destinationsSection: some View {
        Section {
            VStack(spacing: 12) {
                Button(action: { showingDestinationSearch = true }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                        Text("Search Destinations")
                            .foregroundColor(.primary)
                        Spacer()
                        if !selectedDestinations.isEmpty {
                            Text("\(selectedDestinations.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                if selectedDestinations.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("Add at least one destination to get started")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                }
                
                if !selectedDestinations.isEmpty {
                    ForEach(selectedDestinations) { destination in
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(destination.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    selectedDestinations.removeAll { $0.id == destination.id }
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.title3)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Destinations")
                .font(.headline)
        }
    }
    
    // MARK: - Budget Section
    private var budgetSection: some View {
        Section {
            VStack(spacing: 16) {
                // Total Budget
                VStack(alignment: .leading, spacing: 8) {
                    Label("Total Budget", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                            .font(.title3)
                        TextField("0.00", text: $budget)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Budget Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Breakdown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    BudgetRow(icon: "bed.double.fill", label: "Accommodation", amount: $accommodationBudget, currency: settingsManager.currentCurrency.symbol)
                    BudgetRow(icon: "fork.knife", label: "Food & Dining", amount: $foodBudget, currency: settingsManager.currentCurrency.symbol)
                    BudgetRow(icon: "figure.walk", label: "Activities", amount: $activitiesBudget, currency: settingsManager.currentCurrency.symbol)
                    BudgetRow(icon: "airplane", label: "Transportation", amount: $transportationBudget, currency: settingsManager.currentCurrency.symbol)
                }
                
                if totalBudget > 0 {
                    Divider()
                    HStack {
                        Text("Estimated Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(settingsManager.currentCurrency.symbol)\(String(format: "%.2f", totalBudget))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Budget")
                .font(.headline)
        }
    }
    
    // MARK: - Travel Details Section
    private var travelDetailsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Travel Companions
                VStack(alignment: .leading, spacing: 8) {
                    Label("Travel Companions", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Stepper(value: $travelCompanions, in: 1...20) {
                        HStack {
                            Text("\(travelCompanions) \(travelCompanions == 1 ? "person" : "people")")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
                
                // Priority
                VStack(alignment: .leading, spacing: 8) {
                    Label("Priority", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Priority", selection: $priority) {
                        ForEach([TripPriority.low, .medium, .high], id: \.self) { p in
                            HStack {
                                Image(systemName: p.icon)
                                Text(p.displayName)
                            }
                            .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Travel Mode
                VStack(alignment: .leading, spacing: 8) {
                    Label("Travel Mode", systemImage: "car.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Travel Mode", selection: $travelMode) {
                        ForEach([TravelMode.flight, .car, .train, .bus, .cruise, .other], id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Accommodation Type
                VStack(alignment: .leading, spacing: 8) {
                    Label("Accommodation", systemImage: "house.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Accommodation", selection: $accommodationType) {
                        ForEach([AccommodationType.hotel, .airbnb, .hostel, .resort, .camping, .other], id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Weather Preference
                VStack(alignment: .leading, spacing: 8) {
                    Label("Weather Preference", systemImage: "cloud.sun.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("Weather", selection: $weatherPreference) {
                        ForEach([WeatherPreference.any, .sunny, .moderate, .cold], id: \.self) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Travel Details")
                .font(.headline)
        }
    }
    
    // MARK: - Additional Options Section
    private var additionalOptionsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tags", systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Add Tag
                    HStack {
                        TextField("Add tag (e.g., beach, hiking)", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    // Display Tags
                    if !tags.isEmpty {
                        TagFlowLayout(tags: tags, onRemove: removeTag)
                    }
                }
                
                // Reminder
                VStack(alignment: .leading, spacing: 8) {
                    Label("Reminder", systemImage: "bell.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Stepper(value: $reminderDaysBefore, in: 0...30) {
                        HStack {
                            Text("Remind me \(reminderDaysBefore) \(reminderDaysBefore == 1 ? "day" : "days") before")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
                
                // Travel Insurance
                Toggle(isOn: $hasInsurance) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                        Text("Travel Insurance")
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Additional Options")
                .font(.headline)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Notes", systemImage: "note.text")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        Group {
                            if notes.isEmpty {
                                VStack {
                                    HStack {
                                        Text("Add any additional notes, ideas, or reminders for your trip...")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                            .padding(.leading, 12)
                                            .padding(.top, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        },
                        alignment: .topLeading
                    )
                
                if notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("Optional: Add special requests, dietary restrictions, or important reminders")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Additional Notes")
                .font(.headline)
        } footer: {
            if notes.isEmpty {
                Text("You can always add notes later from the trip details page")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            withAnimation {
                tags.append(trimmed)
                newTag = ""
            }
        }
    }
    
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
    
    private func saveTrip() {
        // Validation
        guard isFormValid else {
            if tripName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Please enter a trip name"
            } else if endDate < startDate {
                errorMessage = "End date must be after start date"
            } else {
                errorMessage = "Please check your trip details"
            }
            showErrorAlert = true
            return
        }
        
        isSaving = true
        
        // Use total budget if individual budgets are set, otherwise use main budget
        let budgetValue = totalBudget > 0 ? totalBudget : (Double(budget) ?? nil)
        
        // Build enhanced notes with additional info
        var enhancedNotes = notes
        if !tags.isEmpty {
            if !enhancedNotes.isEmpty {
                enhancedNotes += "\n\n"
            }
            enhancedNotes += "Tags: \(tags.joined(separator: ", "))"
        }
        if travelCompanions > 1 {
            if !enhancedNotes.isEmpty {
                enhancedNotes += "\n"
            }
            enhancedNotes += "Travel Companions: \(travelCompanions)"
        }
        if !enhancedNotes.isEmpty {
            enhancedNotes += "\n"
        }
        enhancedNotes += "Travel Mode: \(travelMode.displayName)"
        enhancedNotes += "\nAccommodation: \(accommodationType.displayName)"
        if hasInsurance {
            enhancedNotes += "\n✓ Travel Insurance"
        }
        if weatherPreference != .any {
            enhancedNotes += "\nWeather Preference: \(weatherPreference.displayName)"
        }
        if priority != .medium {
            enhancedNotes += "\nPriority: \(priority.displayName)"
        }
        
        let newTrip = TripModel(
            name: tripName.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            notes: enhancedNotes,
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
            print("   Budget: \(budgetValue ?? 0)")
            print("   Duration: \(duration) days")
            print("   Completion: \(formCompletionPercentage)%")
            
            // Schedule reminder
            Task {
                let notificationManager = NotificationManager.shared
                let authorized = await notificationManager.requestAuthorization()
                if authorized && reminderDaysBefore > 0 {
                    notificationManager.scheduleTripReminder(trip: newTrip, daysBefore: reminderDaysBefore)
                }
            }
            
            // Haptic feedback
            HapticManager.shared.success()
            
            // Show success and dismiss
            showSuccessAlert = true
            isSaving = false
        } catch {
            print("❌ Failed to save trip: \(error)")
            print("   Error details: \(error.localizedDescription)")
            errorMessage = "Failed to save trip. Please try again."
            showErrorAlert = true
            isSaving = false
            HapticManager.shared.error()
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
}
