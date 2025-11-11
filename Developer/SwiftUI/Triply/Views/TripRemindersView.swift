//
//  TripRemindersView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI

struct TripRemindersView: View {
    @Bindable var trip: TripModel
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var daysBefore: Int = 1
    @State private var showingAuthorizationAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !notificationManager.isAuthorized {
                        Button(action: {
                            Task {
                                let authorized = await notificationManager.requestAuthorization()
                                if !authorized {
                                    showingAuthorizationAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "bell.badge")
                                Text("Enable Notifications")
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Notifications Enabled")
                        }
                    }
                } header: {
                    Text("Notification Status")
                }
                
                if notificationManager.isAuthorized {
                    Section {
                        Picker("Remind Me", selection: $daysBefore) {
                            Text("1 day before").tag(1)
                            Text("3 days before").tag(3)
                            Text("7 days before").tag(7)
                            Text("14 days before").tag(14)
                        }
                        
                        Button(action: {
                            notificationManager.scheduleTripReminder(trip: trip, daysBefore: daysBefore)
                        }) {
                            HStack {
                                Image(systemName: "bell.fill")
                                Text("Schedule Reminder")
                            }
                        }
                    } header: {
                        Text("Trip Reminder")
                    } footer: {
                        Text("Get notified before your trip starts.")
                    }
                }
            }
            .navigationTitle("Trip Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Notifications Disabled", isPresented: $showingAuthorizationAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive trip reminders.")
            }
        }
    }
}



