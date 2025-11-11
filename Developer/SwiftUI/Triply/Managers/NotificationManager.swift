//
//  NotificationManager.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleTripReminder(trip: TripModel, daysBefore: Int = 1) {
        guard isAuthorized else { return }
        
        let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: trip.startDate) ?? trip.startDate
        
        guard reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Trip Reminder: \(trip.name)"
        content.body = "Your trip starts in \(daysBefore) day\(daysBefore == 1 ? "" : "s")!"
        content.sound = .default
        content.badge = 1
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "trip-\(trip.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("✅ Scheduled reminder for trip: \(trip.name)")
            }
        }
    }
    
    func scheduleActivityReminder(activity: ItineraryItem, tripName: String) {
        guard isAuthorized,
              let reminderDate = activity.reminderDate,
              reminderDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Activity Reminder: \(activity.title)"
        content.body = "\(tripName) - \(activity.title) is coming up!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "activity-\(activity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule activity notification: \(error)")
            } else {
                print("✅ Scheduled reminder for activity: \(activity.title)")
            }
        }
    }
    
    func cancelTripReminder(tripId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["trip-\(tripId.uuidString)"])
    }
    
    func cancelActivityReminder(activityId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["activity-\(activityId.uuidString)"])
    }
}



