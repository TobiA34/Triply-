//
//  EmailManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import MessageUI

@MainActor
class EmailManager: ObservableObject {
    static let shared = EmailManager()
    
    let recipientEmail = "tobiadegoroye49@gmail.com"
    
    @Published var canSendMail = false
    
    private init() {
        checkMailAvailability()
    }
    
    private func checkMailAvailability() {
        canSendMail = MFMailComposeViewController.canSendMail()
    }
    
    /// Send email using Mail app
    func sendEmail(subject: String, body: String, completion: @escaping (Bool) -> Void) {
        guard canSendMail else {
            // Fallback: Open Mail app with pre-filled content
            openMailApp(subject: subject, body: body)
            completion(false)
            return
        }
        
        // This will be handled by the view controller
        completion(true)
    }
    
    /// Open Mail app with pre-filled content
    private func openMailApp(subject: String, body: String) {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
        }
    }
    
    /// Create mailto URL
    func createMailtoURL(subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return URL(string: "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
    }
}

// MARK: - Mail Compose View Controller Delegate
class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    var onDismiss: (() -> Void)?
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) {
            self.onDismiss?()
        }
    }
}










