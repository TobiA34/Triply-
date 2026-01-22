//
//  PlanGeneratorView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import EventKit

struct PlanGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var aiFoundation = AppleAIFoundation.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var iapManager = IAPManager.shared
    @State private var isGenerating = false
    @State private var showPaywall = false
    @State private var showCalendarOptions = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let trip: TripModel
    
    var body: some View {
        if !iapManager.isPro {
            PaywallGateView(
                featureName: "AI Plan Generator",
                featureDescription: "Generate complete day-by-day plans for your trip with AI-powered suggestions and calendar integration.",
                icon: "calendar.badge.plus",
                iconColor: .pink
            )
            .navigationTitle("Generate Plan")
        } else {
            planGeneratorContent
        }
    }
    
    private var planGeneratorContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Generate Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create a detailed itinerary and add it to your calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Trip Info
                VStack(alignment: .leading, spacing: 12) {
                    PlanInfoRow(label: "Trip", value: trip.name)
                    PlanInfoRow(label: "Duration", value: "\(trip.duration) days")
                    PlanInfoRow(label: "Dates", value: trip.formattedDateRange)
                    
                    if let budget = trip.budget {
                        PlanInfoRow(label: "Budget", value: SettingsManager.shared.formatAmount(budget))
                    }
                    
                    if let destinations = trip.destinations, !destinations.isEmpty {
                        PlanInfoRow(label: "Destinations", value: "\(destinations.count) location\(destinations.count == 1 ? "" : "s")")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Generate Button
                Button {
                    generatePlan()
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                                .font(.headline)
                        }
                        Text(isGenerating ? "Generating Plan..." : "Generate Plan")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isGenerating)
                .padding(.horizontal)
                
                // Calendar Integration
                if !(trip.itinerary?.isEmpty ?? true) {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal)
                        
                        Text("Add to Calendar")
                            .font(.headline)
                            .padding(.top)
                        
                        Button {
                            showCalendarOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.headline)
                                Text("Add Itinerary to Calendar")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Premium Features Notice
                if !iapManager.isPro {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Pro Feature")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Text("Unlock Pro for unlimited plan generation and advanced features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showPaywall = true
                        } label: {
                            Text("Upgrade to Pro")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Get Plan")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .confirmationDialog("Add to Calendar", isPresented: $showCalendarOptions, titleVisibility: .visible) {
            Button("Add All Itinerary Items") {
                addAllToCalendar()
            }
            Button("Add Trip Only") {
                addTripToCalendar()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            // Refresh calendar authorization status
            calendarManager.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if #available(iOS 17.0, *) {
                calendarManager.isAuthorized = calendarManager.authorizationStatus == .fullAccess || calendarManager.authorizationStatus == .writeOnly
            } else {
                calendarManager.isAuthorized = calendarManager.authorizationStatus == .authorized
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Plan generated and added to calendar successfully!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func generatePlan() {
        // Check if user has Pro (or allow free users limited access)
        let hasAccess = iapManager.isPro || (trip.itinerary?.isEmpty ?? true)
        
        if !hasAccess {
            showPaywall = true
            return
        }
        
        isGenerating = true
        
        Task {
            // Generate structured itinerary using AI
            let structuredResponse = await aiFoundation.generateStructuredChatResponse(
                userMessage: "Create a detailed \(trip.duration)-day itinerary for my trip. Include activities, times, and locations.",
                for: trip,
                conversationHistory: []
            )
            
            await MainActor.run {
                isGenerating = false
                
                // Save itinerary items if available
                if let items = structuredResponse.structuredData?.itineraryItems, !items.isEmpty {
                    Task {
                        do {
                            try await StructuredDataManager.shared.saveItineraryItems(items, to: trip, in: modelContext)
                            
                            // Optionally add to calendar
                            await MainActor.run {
                                showSuccess = true
                                showCalendarOptions = true
                                HapticManager.shared.success()
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to save plan: \(error.localizedDescription)"
                                showError = true
                                HapticManager.shared.error()
                            }
                        }
                    }
                } else {
                    // If no structured items, try to generate them directly
                    print("⚠️ No structured items in response, generating directly...")
                    Task {
                        // Force generate items
                        let forcedItems = await generateItineraryItemsDirectly()
                        if !forcedItems.isEmpty {
                            do {
                                try await StructuredDataManager.shared.saveItineraryItems(forcedItems, to: trip, in: modelContext)
                                await MainActor.run {
                                    showSuccess = true
                                    showCalendarOptions = true
                                    HapticManager.shared.success()
                                }
                            } catch {
                                await MainActor.run {
                                    errorMessage = "Failed to save plan: \(error.localizedDescription)"
                                    showError = true
                                    HapticManager.shared.error()
                                }
                            }
                        } else {
                            await MainActor.run {
                                errorMessage = "Could not generate plan. Please try again or check your trip details."
                                showError = true
                                HapticManager.shared.error()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addAllToCalendar() {
        Task {
            // First check and request permissions if needed
            if !calendarManager.isAuthorized {
                let authorized = await calendarManager.requestAccess()
                if !authorized {
                    await MainActor.run {
                        errorMessage = "Calendar access is required. Please enable it in Settings > Itinero > Calendars."
                        showError = true
                        HapticManager.shared.error()
                    }
                    return
                }
            }
            
            let success = await calendarManager.addItineraryToCalendar(trip)
            await MainActor.run {
                if success {
                    showSuccess = true
                    HapticManager.shared.success()
                } else {
                    errorMessage = "Failed to add to calendar. Please check that you have calendar access enabled in Settings."
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func addTripToCalendar() {
        Task {
            // First check and request permissions if needed
            if !calendarManager.isAuthorized {
                let authorized = await calendarManager.requestAccess()
                if !authorized {
                    await MainActor.run {
                        errorMessage = "Calendar access is required. Please enable it in Settings > Itinero > Calendars."
                        showError = true
                        HapticManager.shared.error()
                    }
                    return
                }
            }
            
            let success = await calendarManager.addTripToCalendar(trip)
            await MainActor.run {
                if success {
                    showSuccess = true
                    HapticManager.shared.success()
                } else {
                    errorMessage = "Failed to add to calendar. Please check that you have calendar access enabled in Settings."
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func generateItineraryItemsDirectly() async -> [StructuredItineraryItem] {
        var items: [StructuredItineraryItem] = []
        let calendar = Calendar.current
        let startDate = trip.startDate
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withTime]
        
        // Generate activities for each day
        let activitiesPerDay = 2
        let totalDays = min(trip.duration, 7) // Limit to 7 days
        
        for day in 1...totalDays {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) else { continue }
            
            // Morning activity
            let morningActivity = getActivityForDay(day: day, timeOfDay: "morning")
            items.append(StructuredItineraryItem(
                id: UUID().uuidString,
                day: day,
                date: dateFormatter.string(from: date),
                title: morningActivity.title,
                details: morningActivity.details,
                time: "09:00",
                location: morningActivity.location,
                order: (day - 1) * activitiesPerDay,
                isBooked: false,
                bookingReference: nil
            ))
            
            // Afternoon activity
            let afternoonActivity = getActivityForDay(day: day, timeOfDay: "afternoon")
            items.append(StructuredItineraryItem(
                id: UUID().uuidString,
                day: day,
                date: dateFormatter.string(from: date),
                title: afternoonActivity.title,
                details: afternoonActivity.details,
                time: "14:00",
                location: afternoonActivity.location,
                order: (day - 1) * activitiesPerDay + 1,
                isBooked: false,
                bookingReference: nil
            ))
        }
        
        return items
    }
    
    private func getActivityForDay(day: Int, timeOfDay: String) -> (title: String, details: String, location: String) {
        let category = trip.category.lowercased()
        let locations = trip.destinations?.map { $0.name } ?? []
        let location = locations.randomElement() ?? "Destination"
        
        var activities: [(title: String, details: String)] = []
        
        switch category {
        case "business":
            activities = [
                ("Business Meeting", "Important business discussion"),
                ("Networking Event", "Connect with industry professionals"),
                ("Client Presentation", "Present your proposal"),
                ("Workshop", "Learn new skills")
            ]
        case "vacation", "leisure":
            activities = [
                ("Beach Time", "Relax and enjoy the sun"),
                ("Local Market Visit", "Explore local culture and food"),
                ("Sightseeing Tour", "Discover famous landmarks"),
                ("Spa & Relaxation", "Unwind and rejuvenate")
            ]
        case "adventure":
            activities = [
                ("Hiking Adventure", "Explore nature trails"),
                ("Water Sports", "Try exciting water activities"),
                ("Mountain Climbing", "Challenge yourself"),
                ("Wildlife Safari", "See amazing wildlife")
            ]
        default:
            activities = [
                ("City Tour", "Explore the city highlights"),
                ("Museum Visit", "Learn about local history"),
                ("Local Restaurant", "Try authentic cuisine"),
                ("Shopping", "Find unique souvenirs")
            ]
        }
        
        let activity = activities.randomElement() ?? ("Activity", "Enjoy your time")
        return (title: activity.title, details: activity.details, location: location)
    }
}

struct PlanInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

