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
    @EnvironmentObject private var themeManager: ThemeManager
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
    
    // Cover Photo
    @State private var coverImageData: Data? = nil
    @State private var showingImagePicker = false

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
    
    private func localizedCategory(_ category: String) -> String {
        switch category {
        case "General": return "addTrip.categoryGeneral".localized
        case "Adventure": return "addTrip.categoryAdventure".localized
        case "Business": return "addTrip.categoryBusiness".localized
        case "Relaxation": return "addTrip.categoryRelaxation".localized
        case "Family": return "addTrip.categoryFamily".localized
        case "Romantic": return "addTrip.categoryRomantic".localized
        case "Solo": return "addTrip.categorySolo".localized
        case "Group": return "addTrip.categoryGroup".localized
        default: return category
        }
    }
    
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
            return .invalid("addTrip.enterTotalBudget".localized)
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
        let total = 9
        
        if !tripName.isEmpty { completed += 1 }
        if selectedCategory != "General" { completed += 1 }
        if !selectedDestinations.isEmpty { completed += 1 }
        if totalBudget > 0 || !budget.isEmpty { completed += 1 }
        if travelCompanions > 1 { completed += 1 }
        if !notes.isEmpty { completed += 1 }
        if !tags.isEmpty { completed += 1 }
        if hasInsurance || reminderDaysBefore > 0 { completed += 1 }
        
        if coverImageData != nil { completed += 1 }
        
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
            
            // Cover Photo Section
            Section {
                Button(action: { showingImagePicker = true }) {
                    ZStack {
                        if let data = coverImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .overlay(Color.black.opacity(0.3))
                        } else {
                            Rectangle()
                                .fill(themeManager.currentPalette.accent.opacity(0.1))
                                .frame(height: 160)
                        }
                        
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                            Text(coverImageData == nil ? "Add Cover Photo" : "Change Photo")
                                .font(.headline)
                        }
                        .foregroundColor(coverImageData == nil ? themeManager.currentPalette.accent : .white)
                    }
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .cornerRadius(16)
            .padding(.bottom, 8)
            .listRowSeparator(.hidden)
            
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
        .scrollContentBackground(.hidden)
        .background(themeManager.currentPalette.background)
        .formStyle(.grouped)
        .navigationTitle("trips.new".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    HapticManager.shared.selection()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("common.back".localized)
                    }
                    .foregroundColor(themeManager.currentPalette.accent)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save".localized) {
                    saveTrip()
                }
                .disabled(!isFormValid || isSaving)
                .fontWeight(.semibold)
                .foregroundColor(isFormValid && !isSaving ? themeManager.currentPalette.accent : .secondary)
                .accessibilityLabel("common.save".localized)
                .accessibilityHint("addTrip.accessibilitySaveHint".localized)
                .accessibilityIdentifier("Save")
            }
        }
        .alert("alert.limitReached".localized, isPresented: $showLimitAlert) {
            Button("pro.upgrade".localized) {
                showingPaywall = true
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            if let message = limitAlertMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView(onImageSelected: { image in
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    coverImageData = imageData
                }
            })
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .keyboardDoneButton()
        .fullScreenCover(isPresented: $showingTemplateLibrary) {
            SmartTemplateLibraryView { template in
                Task { @MainActor in
                    applySmartTemplate(template)
                    showingTemplateLibrary = false
                }
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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Label("addTrip.quickTemplates".localized, systemImage: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.text)
                    Spacer()
                    Button(action: {
                        HapticManager.shared.selection()
                        showTemplates.toggle()
                    }) {
                        Image(systemName: showTemplates ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentPalette.accent)
                    }
                }
                
                if showTemplates {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("addTrip.tapTemplateHint".localized)
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentPalette.secondaryText)
                            
                            Spacer()
                            
                            Button {
                                HapticManager.shared.selection()
                                showingTemplateLibrary = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.grid.2x2")
                                    Text("addTrip.browseAll".localized)
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(themeManager.currentPalette.accent)
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                TemplateCard(
                                    icon: "beach.umbrella.fill",
                                    title: "addTrip.beachVacation".localized,
                                    color: .blue,
                                    action: {
                                        applyTemplate(.beach)
                                    }
                                )
                                TemplateCard(
                                    icon: "mountain.2.fill",
                                    title: "addTrip.mountainAdventure".localized,
                                    color: .green,
                                    action: {
                                        applyTemplate(.mountain)
                                    }
                                )
                                TemplateCard(
                                    icon: "building.2.fill",
                                    title: "addTrip.cityBreak".localized,
                                    color: .purple,
                                    action: {
                                        applyTemplate(.city)
                                    }
                                )
                                TemplateCard(
                                    icon: "airplane",
                                    title: "addTrip.businessTrip".localized,
                                    color: .orange,
                                    action: {
                                        applyTemplate(.business)
                                    }
                                )
                                TemplateCard(
                                    icon: "heart.fill",
                                    title: "addTrip.romanticGetaway".localized,
                                    color: .pink,
                                    action: {
                                        applyTemplate(.romantic)
                                    }
                                )
                            }
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                        }
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.getStarted".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Label("addTrip.tipsSuggestions".localized, systemImage: "lightbulb.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeManager.currentPalette.text)
                    Spacer()
                    Button(action: {
                        HapticManager.shared.selection()
                        showTips.toggle()
                    }) {
                        Image(systemName: showTips ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentPalette.accent)
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
                                text: "addTrip.tipMultiCity".localized,
                                color: .blue
                            )
                        }
                        
                        if totalBudget > 0 {
                            TipRow(
                                icon: settingsManager.currencyIconName(filled: true),
                                text: "addTrip.tipBudget".localized,
                                color: .green
                            )
                        }
                        
                        if duration > 7 {
                            TipRow(
                                icon: "calendar.badge.clock",
                                text: "addTrip.tipItinerary".localized,
                                color: .purple
                            )
                        }
                        
                        // Always show a helpful tip
                        if selectedDestinations.isEmpty && totalBudget == 0 {
                            TipRow(
                                icon: "arrow.right.circle.fill",
                                text: "addTrip.tipStartPlanning".localized,
                                color: .blue
                            )
                        }
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.helpfulTips".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Stats Preview Section
    private var statsPreviewSection: some View {
        Section {
            VStack(spacing: 12) {
                Text("addTrip.tripSummary".localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isFormValid {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            icon: "calendar",
                            label: "trips.duration".localized,
                            value: "\(duration) \(duration == 1 ? "trips.day".localized : "trips.days".localized)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "person.2.fill",
                            label: "addTripView.travelers".localized,
                            value: "\(travelCompanions)",
                            color: .purple
                        )
                        
                        if totalBudget > 0 {
                            StatCard(
                                icon: settingsManager.currencyIconName(filled: true),
                                label: "trips.budget".localized,
                                value: "\(settingsManager.currentCurrency.symbol)\(String(format: "%.0f", totalBudget))",
                                color: .green
                            )
                        }
                        
                        StatCard(
                            icon: "mappin.circle.fill",
                            label: "addTripView.destinations".localized,
                            value: "\(selectedDestinations.count)",
                            color: .orange
                        )
                    }
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text("addTrip.completeFormForSummary".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.preview".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Helper Functions
    private func getCategoryTip() -> String {
        switch selectedCategory {
        case "Adventure":
            return "addTrip.tipAdventure".localized
        case "Business":
            return "addTrip.tipBusiness".localized
        case "Relaxation":
            return "addTrip.tipRelaxation".localized
        case "Family":
            return "addTrip.tipFamily".localized
        case "Romantic":
            return "addTrip.tipRomantic".localized
        case "Solo":
            return "addTrip.tipSolo".localized
        default:
            return "addTrip.tipStartPlanning".localized
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
                tripName = "addTrip.beachVacation".localized
                selectedCategory = "Relaxation"
                travelMode = .flight
                accommodationType = .resort
                weatherPreference = .sunny
                tags = ["beach", "relaxation", "sun"]
                reminderDaysBefore = 3
            case .mountain:
                tripName = "addTrip.mountainAdventure".localized
                selectedCategory = "Adventure"
                travelMode = .car
                accommodationType = .camping
                weatherPreference = .cold
                tags = ["hiking", "nature", "adventure"]
                reminderDaysBefore = 5
            case .city:
                tripName = "addTrip.cityBreak".localized
                selectedCategory = "General"
                travelMode = .flight
                accommodationType = .hotel
                weatherPreference = .moderate
                tags = ["city", "culture", "sightseeing"]
                reminderDaysBefore = 2
            case .business:
                tripName = "addTrip.businessTrip".localized
                selectedCategory = "Business"
                travelMode = .flight
                accommodationType = .hotel
                weatherPreference = .any
                tags = ["business", "work"]
                reminderDaysBefore = 1
            case .romantic:
                tripName = "addTrip.romanticGetaway".localized
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
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Trip Name or Welcome Message
            VStack(spacing: DesignSystem.Spacing.xs) {
                if !tripName.isEmpty {
                    Text(tripName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeManager.currentPalette.text)
                } else {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("addTrip.newAdventureAwaits".localized)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(themeManager.currentPalette.text)
                        Text("addTrip.fillDetailsBelow".localized)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                    }
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("addTrip.progress".localized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                    Spacer()
                    Text("addTripView.formcompletionpercentage".localized(formCompletionPercentage))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(formCompletionPercentage == 100 ? .green : themeManager.currentPalette.accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                            .fill(formCompletionPercentage == 100 ? Color.green : themeManager.currentPalette.accent)
                            .frame(width: max(0, geo.size.width * CGFloat(formCompletionPercentage) / 100), height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            // Stats Row
            HStack(spacing: DesignSystem.Spacing.sm) {
                if duration > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(duration) \(duration == 1 ? "trips.day".localized : "trips.days".localized)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(themeManager.currentPalette.accent)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(themeManager.currentPalette.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                if !selectedDestinations.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text("addTripView.selecteddestinationscount".localized(selectedDestinations.count))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                if totalBudget > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: settingsManager.currencyIconName(filled: true))
                            .font(.system(size: 12))
                        Text(settingsManager.formatAmount(totalBudget))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .fill(themeManager.currentPalette.background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                        .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        Section {
            VStack(spacing: 20) {
                // Trip Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("trips.name".localized, systemImage: "text.book.closed.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("", text: $tripName)
                        .textFieldStyle(.plain)
                        .foregroundColor(.primary)
                        .font(.system(size: 17))
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .fill(Color(.tertiarySystemGroupedBackground))
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
                            Text("addTrip.giveMemorableName".localized)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Category
                VStack(alignment: .leading, spacing: 8) {
                    Label("addTrip.category".localized, systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack {
                                    Text(localizedCategory(category))
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(localizedCategory(selectedCategory))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }
                
                // Dates
                VStack(alignment: .leading, spacing: 12) {
                    Label("addTrip.startDate".localized, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker("trips.startDate".localized, selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .onChange(of: startDate) { _, _ in
                            Task { @MainActor in
                            validateDates()
                            }
                        }
                    
                    DatePicker("trips.endDate".localized, selection: $endDate, in: startDate..., displayedComponents: .date)
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
                            Text("addTrip.endDateAfterStart".localized)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.basicInfo".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Destinations Section
    private var destinationsSection: some View {
        Section {
            VStack(spacing: 12) {
                Button(action: {
                    let check = proLimiter.canAddDestination(currentDestinationCount: selectedDestinations.count, tripName: tripName.isEmpty ? "trips.new".localized : tripName)
                    if check.allowed {
                        showingDestinationSearch = true
                    } else {
                        limitAlertMessage = check.reason
                        showLimitAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentPalette.accent)
                        Text("addTrip.searchDestinations".localized)
                            .font(.body.weight(.medium))
                            .foregroundColor(themeManager.currentPalette.text)
                        Spacer()
                        if !selectedDestinations.isEmpty {
                            Text("addTripView.selecteddestinationscount".localized(selectedDestinations.count))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(themeManager.currentPalette.accent)
                                .clipShape(Capsule())
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
                
                if selectedDestinations.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                        Text("addTrip.addOneDestination".localized)
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
                        .padding(DesignSystem.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("destination.title".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Budget Section
    private var budgetSection: some View {
        Section {
            VStack(spacing: 16) {
                // Total Budget
                VStack(alignment: .leading, spacing: 8) {
                    Label("addTrip.totalBudget".localized, systemImage: settingsManager.currencyIconName(filled: true))
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
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    
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
                    Text("addTrip.budgetBreakdown".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BudgetRow(icon: "bed.double.fill", label: "expense.categories.accommodation".localized, amount: $accommodationBudget, currency: settingsManager.currentCurrency.symbol)
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
                        BudgetRow(icon: "fork.knife", label: "expense.categories.food".localized, amount: $foodBudget, currency: settingsManager.currentCurrency.symbol)
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
                        BudgetRow(icon: "figure.walk", label: "addTripView.activities".localized, amount: $activitiesBudget, currency: settingsManager.currentCurrency.symbol)
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
                        BudgetRow(icon: "airplane", label: "addTripView.transportation".localized, amount: $transportationBudget, currency: settingsManager.currentCurrency.symbol)
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
                        Text("addTrip.estimatedTotal".localized)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(settingsManager.currentCurrency.symbol)\(String(format: "%.2f", totalBudget))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("trips.budget".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Travel Details Section
    private var travelDetailsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Travel Companions
                VStack(alignment: .leading, spacing: 8) {
                    Label("addTrip.travelCompanions".localized, systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Stepper(value: $travelCompanions, in: 1...50) {
                        HStack {
                            Text("\(travelCompanions) \(travelCompanions == 1 ? "common.person".localized : "common.people".localized)")
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
                    Label("addTrip.priority".localized, systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("addTrip.priority".localized, selection: $priority) {
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
                    Label("addTrip.travelMode".localized, systemImage: "car.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("addTrip.travelMode".localized, selection: $travelMode) {
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
                    Label("addTrip.accommodation".localized, systemImage: "house.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("addTrip.accommodation".localized, selection: $accommodationType) {
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
                    Label("addTrip.weatherPreference".localized, systemImage: "cloud.sun.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Picker("addTrip.weatherPreference".localized, selection: $weatherPreference) {
                        ForEach([WeatherPreference.any, .sunny, .moderate, .cold], id: \.self) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.travelDetails".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Additional Options Section
    private var additionalOptionsSection: some View {
        Section {
            VStack(spacing: 16) {
                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Label("addTrip.tags".localized, systemImage: "tag.fill")
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
                            Text("addTrip.maxTags".localized)
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
                    Label("addTrip.reminder".localized, systemImage: "bell.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Stepper(value: $reminderDaysBefore, in: 0...30) {
                        HStack {
                            Text("addTrip.remindMeBefore".localized(reminderDaysBefore, reminderDaysBefore == 1 ? "trips.day".localized : "trips.days".localized))
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
                        Text("addTrip.travelInsurance".localized)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.additionalOptions".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("addTrip.notes".localized, systemImage: "note.text")
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
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(Color(.tertiarySystemGroupedBackground))
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
                        Text("addTrip.notesOptional".localized)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .listRowBackground(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        } header: {
            Text("addTrip.additionalNotes".localized)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(themeManager.currentPalette.secondaryText)
        } footer: {
            if notes.isEmpty {
                Text("addTrip.notesHint".localized)
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
            errorMessage = validation.errorMessage ?? "addTrip.validationMessage".localized
            
            // Show cool animated error alert
            AlertManager.shared.showError(
                "addTrip.validationError".localized,
                message: errorMessage,
                duration: 3.0
            )
            return
        }
        
        isSaving = true
        
        // Use total budget if individual budgets are set, otherwise use main budget
        let budgetValue = totalBudget > 0 ? totalBudget : (Double(budget) ?? nil)
        
        // Build enhanced notes with additional info (localized labels)
        var enhancedNotes = notes
        if !tags.isEmpty {
            if !enhancedNotes.isEmpty {
                enhancedNotes += "\n\n"
            }
            enhancedNotes += "\("addTrip.notesLabelTags".localized): \(tags.joined(separator: ", "))"
        }
        if travelCompanions > 1 {
            if !enhancedNotes.isEmpty {
                enhancedNotes += "\n"
            }
            enhancedNotes += "\("addTrip.notesLabelTravelCompanions".localized): \(travelCompanions)"
        }
        if !enhancedNotes.isEmpty {
            enhancedNotes += "\n"
        }
        enhancedNotes += "\("addTrip.notesLabelTravelMode".localized): \(travelMode.displayName)"
        enhancedNotes += "\n\("addTrip.notesLabelAccommodation".localized): \(accommodationType.displayName)"
        if hasInsurance {
            enhancedNotes += "\n✓ \("addTrip.travelInsurance".localized)"
        }
        if weatherPreference != .any {
            enhancedNotes += "\n\("addTrip.notesLabelWeatherPreference".localized): \(weatherPreference.displayName)"
        }
        if priority != .medium {
            enhancedNotes += "\n\("addTrip.notesLabelPriority".localized): \(priority.displayName)"
        }
        
        let newTrip = TripModel(
            name: tripName.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            notes: enhancedNotes,
            category: selectedCategory,
            budget: budgetValue
        )
        
        if let coverImageData = coverImageData {
            newTrip.coverImageData = coverImageData
        }
        
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
                "addTrip.tripCreated".localized,
                message: "addTripView.newtripname.has.been.added.to".localized(newTrip.name),
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
            errorMessage = "addTrip.saveFailedMessage".localized
            
            // Show cool animated error alert
            AlertManager.shared.showError(
                "addTrip.saveFailed".localized,
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
        .environmentObject(ThemeManager.shared)
}
