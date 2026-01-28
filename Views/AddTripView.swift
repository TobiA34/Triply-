//
//  AddTripView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UserNotifications
import WidgetKit

struct AddTripView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var searchManager = DestinationSearchManager()
    @StateObject private var proLimiter = ProLimiter.shared
    @StateObject private var templateManager = SmartTemplateManager.shared
    private let settingsManager = SettingsManager.shared
    
    // Optional template to pre-fill the form
    let selectedTemplate: SmartTripTemplate?
    
    init(selectedTemplate: SmartTripTemplate? = nil) {
        self.selectedTemplate = selectedTemplate
    }
    
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
    @State private var showingTemplateLibrary = false
    @State private var showingPaywall = false
    @State private var limitAlertMessage: String?
    @State private var showLimitAlert = false
    
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
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var showTemplates = true  // Show templates by default
    @State private var showTips = true  // Show tips by default
    @State private var fieldErrors: [String: String] = [:]
    
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
        validateForm().isValid
    }
    
    private func validateForm() -> ValidationResult {
        // Validate trip name
        let nameResult = FormValidator.validateTripName(tripName)
        if !nameResult.isValid {
            return nameResult
        }
        
        // Validate dates
        let dateResult = FormValidator.validateTripDates(startDate: startDate, endDate: endDate)
        if !dateResult.isValid {
            return dateResult
        }
        
        // Validate total budget (mandatory)
        if budget.isEmpty {
            return .invalid("Please enter a total trip budget.")
        } else {
            let budgetResult = FormValidator.validateBudget(budget)
            if !budgetResult.isValid {
                return budgetResult
            }
        }
        
        if !accommodationBudget.isEmpty {
            let result = FormValidator.validateBudget(accommodationBudget)
            if !result.isValid { return result }
        }
        
        if !foodBudget.isEmpty {
            let result = FormValidator.validateBudget(foodBudget)
            if !result.isValid { return result }
        }
        
        if !activitiesBudget.isEmpty {
            let result = FormValidator.validateBudget(activitiesBudget)
            if !result.isValid { return result }
        }
        
        if !transportationBudget.isEmpty {
            let result = FormValidator.validateBudget(transportationBudget)
            if !result.isValid { return result }
        }
        
        // Validate travel companions
        let companionsResult = FormValidator.validateTravelCompanions(travelCompanions)
        if !companionsResult.isValid {
            return companionsResult
        }
        
        // Validate tags
        let tagsResult = FormValidator.validateTags(tags)
        if !tagsResult.isValid {
            return tagsResult
        }
        
        // Validate notes
        let notesResult = FormValidator.validateTripNotes(notes)
        if !notesResult.isValid {
            return notesResult
        }
        
        return .valid
    }
    
    // Helper function to validate dates
    private func validateDates() {
        let result = FormValidator.validateTripDates(startDate: startDate, endDate: endDate)
        if result.isValid {
            fieldErrors.removeValue(forKey: "dates")
        } else {
            fieldErrors["dates"] = result.errorMessage
        }
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
        .navigationTitle("New Trip")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTrip()
                }
                .disabled(!isFormValid || isSaving)
                .fontWeight(.semibold)
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
        .keyboardDoneButton()
        .fullScreenCover(isPresented: $showingTemplateLibrary) {
            SmartTemplateLibraryView { template in
                applySmartTemplate(template)
            }
        }
        .fullScreenCover(isPresented: $showingDestinationSearch) {
            DestinationSearchView(
                searchManager: searchManager,
                selectedDestinations: $selectedDestinations
            )
        }
        .task {
            // Apply template if provided (using task for async safety)
            if let template = selectedTemplate {
                // Small delay to ensure view is fully initialized
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                applySmartTemplate(template)
            }
        }
        // Cool animated alerts are now handled by AlertManager
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
                        HStack {
                            Text("Tap a template to quickly fill in common trip details")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button {
                                showingTemplateLibrary = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "square.grid.2x2")
                                    Text("Browse All")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
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
                                text: "Start planning your trip by adding destinations and setting a budget",
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
                            label: "destinations",
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
    
    private func applySmartTemplate(_ template: SmartTripTemplate) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Basic info
            tripName = template.name
            selectedCategory = template.category
            notes = template.details
            
            // Dates - set end date based on suggested duration
            let newEndDate = Calendar.current.date(byAdding: .day, value: template.suggestedDuration - 1, to: startDate) ?? endDate
            endDate = newEndDate
            
            // Budget
            if let budget = template.suggestedBudget, budget > 0 {
                self.budget = String(format: "%.0f", budget)
            }
            
            // Tags and reminders
            tags = template.tags
            reminderDaysBefore = max(1, template.suggestedDuration / 2)
            
            // Apply suggested destinations if available
            if !template.suggestedDestinations.isEmpty {
                // Convert destination names to SearchResult objects
                selectedDestinations = template.suggestedDestinations.map { name in
                    SearchResult(
                        id: UUID().uuidString,
                        name: name,
                        address: "",
                        country: "",
                        coordinates: nil
                    )
                }
            }
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
                    TextField("", text: $tripName)
                        .textFieldStyle(.plain)
                        .foregroundColor(.primary)
                        .font(.system(size: 17))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .accessibilityIdentifier("Trip Name")
                        .textInputAutocapitalization(.words)
                        .onChange(of: tripName) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                Task { @MainActor in
                                tripName = oldValue
                                // Trigger haptic feedback
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                                }
                            }
                        }
                        .onChange(of: tripName) { _, newValue in
                            Task { @MainActor in
                            let result = FormValidator.validateTripName(newValue)
                            if result.isValid {
                                fieldErrors.removeValue(forKey: "tripName")
                            } else {
                                fieldErrors["tripName"] = result.errorMessage
                                }
                            }
                        }
                    
                    if let error = fieldErrors["tripName"] {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else if tripName.isEmpty {
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
                                    Text(category)
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory)
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
                    Label("Start Date", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: startDate) { _, _ in
                            Task { @MainActor in
                            validateDates()
                            }
                        }
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: endDate) { _, _ in
                            Task { @MainActor in
                            validateDates()
                            }
                        }
                    
                    // Date validation warning
                    if let error = fieldErrors["dates"] {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    } else if endDate < startDate {
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
                Button(action: {
                    let check = proLimiter.canAddDestination(currentDestinationCount: selectedDestinations.count, tripName: tripName.isEmpty ? "New Trip" : tripName)
                    if check.allowed {
                        showingDestinationSearch = true
                    } else {
                        limitAlertMessage = check.reason
                        showLimitAlert = true
                    }
                }) {
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
            Text("destinations")
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
                        TextField("", text: $budget)
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .onChange(of: budget) { _, newValue in
                                Task { @MainActor in
                                let result = FormValidator.validateBudget(newValue)
                                if result.isValid {
                                    fieldErrors.removeValue(forKey: "budget")
                                } else {
                                    fieldErrors["budget"] = result.errorMessage
                                    }
                                }
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if let error = fieldErrors["budget"] {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }
                }
                
                // Budget Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Breakdown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BudgetRow(icon: "bed.double.fill", label: "Accommodation", amount: $accommodationBudget, currency: settingsManager.currentCurrency.symbol)
                            .onChange(of: accommodationBudget) { _, newValue in
                                Task { @MainActor in
                                let result = FormValidator.validateBudget(newValue)
                                if result.isValid {
                                    fieldErrors.removeValue(forKey: "accommodationBudget")
                                } else {
                                    fieldErrors["accommodationBudget"] = result.errorMessage
                                    }
                                }
                            }
                        if let error = fieldErrors["accommodationBudget"] {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 36)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BudgetRow(icon: "fork.knife", label: "Food", amount: $foodBudget, currency: settingsManager.currentCurrency.symbol)
                            .onChange(of: foodBudget) { _, newValue in
                                Task { @MainActor in
                                let result = FormValidator.validateBudget(newValue)
                                if result.isValid {
                                    fieldErrors.removeValue(forKey: "foodBudget")
                                } else {
                                    fieldErrors["foodBudget"] = result.errorMessage
                                    }
                                }
                            }
                        if let error = fieldErrors["foodBudget"] {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 36)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BudgetRow(icon: "figure.walk", label: "Activities", amount: $activitiesBudget, currency: settingsManager.currentCurrency.symbol)
                            .onChange(of: activitiesBudget) { _, newValue in
                                Task { @MainActor in
                                let result = FormValidator.validateBudget(newValue)
                                if result.isValid {
                                    fieldErrors.removeValue(forKey: "activitiesBudget")
                                } else {
                                    fieldErrors["activitiesBudget"] = result.errorMessage
                                    }
                                }
                            }
                        if let error = fieldErrors["activitiesBudget"] {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 36)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BudgetRow(icon: "airplane", label: "Transportation", amount: $transportationBudget, currency: settingsManager.currentCurrency.symbol)
                            .onChange(of: transportationBudget) { _, newValue in
                                Task { @MainActor in
                                let result = FormValidator.validateBudget(newValue)
                                if result.isValid {
                                    fieldErrors.removeValue(forKey: "transportationBudget")
                                } else {
                                    fieldErrors["transportationBudget"] = result.errorMessage
                                    }
                                }
                            }
                        if let error = fieldErrors["transportationBudget"] {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 36)
                        }
                    }
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
                    Stepper(value: $travelCompanions, in: 1...50) {
                        HStack {
                            Text("\(travelCompanions) \(travelCompanions == 1 ? "person" : "people")")
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .onChange(of: travelCompanions) { _, newValue in
                        Task { @MainActor in
                        let result = FormValidator.validateTravelCompanions(newValue)
                        if result.isValid {
                            fieldErrors.removeValue(forKey: "travelCompanions")
                        } else {
                            fieldErrors["travelCompanions"] = result.errorMessage
                            }
                        }
                    }
                    
                    if let error = fieldErrors["travelCompanions"] {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
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
                    Picker("Weather Preference", selection: $weatherPreference) {
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
                        TextField("", text: $newTag)
                            .onChange(of: newTag) { oldValue, newValue in
                                if ContentFilter.containsBlockedContent(newValue) {
                                    Task { @MainActor in
                                    newTag = oldValue
                                    }
                                }
                            }
                            .textFieldStyle(.plain)
                            .foregroundColor(.primary)
                            .font(.system(size: 17))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTag.isEmpty)
                    
                    if let error = fieldErrors["newTag"] {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }
                    
                    if tags.count >= 10 {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .font(.caption2)
                            Text("Maximum 10 tags allowed")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                    }
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
                            Text(String(format: "Remind me %d %@ before", reminderDaysBefore, reminderDaysBefore == 1 ? "day" : "days"))
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
                    .onChange(of: notes) { oldValue, newValue in
                        if ContentFilter.containsBlockedContent(newValue) {
                            Task { @MainActor in
                            notes = oldValue
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 17))
                    .frame(minHeight: 150)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .onChange(of: notes) { _, newValue in
                        Task { @MainActor in
                        let result = FormValidator.validateTripNotes(newValue)
                        if result.isValid {
                            fieldErrors.removeValue(forKey: "notes")
                        } else {
                            fieldErrors["notes"] = result.errorMessage
                            }
                        }
                    }
                
                if let error = fieldErrors["notes"] {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
                
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
        // Comprehensive validation
        let validation = validateForm()
        guard validation.isValid else {
            errorMessage = validation.errorMessage ?? "Please check your trip details"
            
            // Show cool animated error alert
            AlertManager.shared.showError(
                "Validation Error",
                message: errorMessage,
                duration: 3.0
            )
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
                    order: index,
                    latitude: searchResult.coordinates?.latitude,
                    longitude: searchResult.coordinates?.longitude
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
            #if DEBUG
            print("✅ Trip saved successfully: \(newTrip.name)")
            print("   Destinations: \(newTrip.destinations?.count ?? 0)")
            print("   Budget: \(budgetValue ?? 0)")
            print("   Duration: \(duration) days")
            print("   Completion: \(formCompletionPercentage)%")
            #endif
            
            // Sync to widgets immediately
            Task { @MainActor in
                let allTrips = try? modelContext.fetch(FetchDescriptor<TripModel>())
                if let trips = allTrips {
                    WidgetDataSync.shared.syncTrips(trips)
                    // Reload widgets
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            
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
            
            // Show cool animated success alert
            AlertManager.shared.showSuccess(
                "Trip Created!",
                message: "\(newTrip.name) has been added to your trips",
                duration: 2.0
            )
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
            
            isSaving = false
        } catch {
            #if DEBUG
            print("❌ Failed to save trip: \(error)")
            print("   Error details: \(error.localizedDescription)")
            #endif
            errorMessage = "Failed to save trip. Please try again."
            
            // Show cool animated error alert
            AlertManager.shared.showError(
                "Save Failed",
                message: errorMessage,
                duration: 3.0
            )
            
            isSaving = false
            HapticManager.shared.error()
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: [TripModel.self, DestinationModel.self], inMemory: true)
}



//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UserNotifications
