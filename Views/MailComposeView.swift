//
//  MailComposeView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let recipientEmail: String
    let subject: String
    let body: String
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipientEmail])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            // Dismiss the mail composer controller
            // This is required by MFMailComposeViewController
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                // Update binding on main thread to dismiss the SwiftUI sheet
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
                // Call onDismiss callback after sheet is dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.parent.onDismiss?()
                }
            }
        }
    }
}



