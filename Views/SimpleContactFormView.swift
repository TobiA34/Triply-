//
//  SimpleContactFormView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import MessageUI
import UIKit

struct SimpleContactFormView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var subject = ""
    @State private var message = ""
    @State private var showMailComposer = false
    @State private var showContentWarning = false
    @State private var contentWarningMessage = ""
    @State private var mailDelegate = MailDelegate()
    
    private let recipientEmail = "tobiadegoroye49@gmail.com"
    private let contentFilter = ContentFilterManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Subject", text: $subject)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Subject")
                }
                
                Section {
                    TextEditor(text: $message)
                        .frame(height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                } header: {
                    Text("Message")
                } footer: {
                    Text("Describe your feedback, issue, or feature request.")
                }
                
                Section {
                    Button {
                        sendEmail()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Email")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            (subject.isEmpty || message.isEmpty) ? Color.gray : Color.blue
                        )
                        .cornerRadius(12)
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeViewControllerWrapper(
                    recipientEmail: recipientEmail,
                    subject: subject,
                    body: message,
                    isPresented: $showMailComposer
                ) {
                    dismiss()
                }
            }
            .alert("Content Warning", isPresented: $showContentWarning) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(contentWarningMessage)
            }
        }
    }
    
    private func sendEmail() {
        // Check for inappropriate content
        let subjectValidation = contentFilter.validateContent(subject)
        let messageValidation = contentFilter.validateContent(message)
        
        if !subjectValidation.isValid {
            contentWarningMessage = subjectValidation.errorMessage ?? "Your subject contains inappropriate content."
            showContentWarning = true
            return
        }
        
        if !messageValidation.isValid {
            contentWarningMessage = messageValidation.errorMessage ?? "Your message contains inappropriate content."
            showContentWarning = true
            return
        }
        
        // Filter content
        let filteredSubject = contentFilter.filterContent(subject)
        let filteredMessage = contentFilter.filterContent(message)
        
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Open Mail app with mailto URL
            let subjectEncoded = filteredSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = filteredMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
                UIApplication.shared.open(url)
                dismiss()
            }
        }
    }
}

// MARK: - Mail Compose View Controller Wrapper
struct MailComposeViewControllerWrapper: UIViewControllerRepresentable {
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
        let parent: MailComposeViewControllerWrapper
        
        init(_ parent: MailComposeViewControllerWrapper) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            // Dismiss the controller first (required)
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                // Update binding on main thread
                DispatchQueue.main.async {
                    self.parent.isPresented = false
                }
                // Call onDismiss after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.parent.onDismiss?()
                }
            }
        }
    }
}

// MARK: - Mail Delegate
class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

#Preview {
    SimpleContactFormView()
}



