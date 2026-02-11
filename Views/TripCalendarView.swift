//
//  TripCalendarView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import EventKit

struct TripCalendarView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var isAddingToCalendar = false
    @State private var showSuccess = false
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    let trip: TripModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if calendarManager.isAuthorized {
                    CalendarAuthorizedView(
                        trip: trip,
                        onAdd: addToCalendar,
                        onRemove: removeFromCalendar
                    )
                } else {
                    CalendarUnauthorizedView(onRequestAccess: requestAccess)
                }
            }
            .padding()
        }
        .navigationTitle("Add to Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { }
        } message: {
            Text("Trip added to calendar successfully!")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Failed to add trip to calendar. Please check permissions.")
        }
        .onAppear {
            // Refresh authorization status
            calendarManager.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            if #available(iOS 17.0, *) {
                calendarManager.isAuthorized = calendarManager.authorizationStatus == .fullAccess || calendarManager.authorizationStatus == .writeOnly
            } else {
                calendarManager.isAuthorized = calendarManager.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestAccess() {
        Task {
            let authorized = await calendarManager.requestAccess()
            if authorized {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        }
    }
    
    private func addToCalendar() {
        isAddingToCalendar = true
        Task {
            let success = await calendarManager.addTripToCalendar(trip)
            await MainActor.run {
                isAddingToCalendar = false
                if success {
                    showSuccess = true
                    HapticManager.shared.success()
                } else {
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func removeFromCalendar() {
        Task {
            let success = await calendarManager.removeTripFromCalendar(trip)
            await MainActor.run {
                if success {
                    HapticManager.shared.success()
                } else {
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct CalendarAuthorizedView: View {
    let trip: TripModel
    let onAdd: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Add to Calendar")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                CalendarInfoRow(label: "Trip", value: trip.name)
                CalendarInfoRow(label: "Start", value: formatDate(trip.startDate))
                CalendarInfoRow(label: "End", value: formatDate(trip.endDate))
                CalendarInfoRow(label: "Duration", value: "\(trip.duration) days")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button {
                onAdd()
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Calendar")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CalendarUnauthorizedView: View {
    let onRequestAccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Add to Calendar")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("To add this trip and get reminders, your device will ask for calendar access.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                onRequestAccess()
            } label: {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Add to Calendar")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
}

struct CalendarInfoRow: View {
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

