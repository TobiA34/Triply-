//
//  NotificationDelegate.swift
//  Itinero
//
//  Handles rich notification actions (iOS 18+)
//

import Foundation
import UserNotifications

@available(iOS 18.0, *)
public class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationDelegate()
    
    public override init() {
        super.init()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        let actionIdentifier = response.actionIdentifier
        Task { @MainActor in
            NotificationManager.shared.handleNotificationAction(
                identifier: actionIdentifier,
                userInfo: userInfo
            )
        }
        
        completionHandler()
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
