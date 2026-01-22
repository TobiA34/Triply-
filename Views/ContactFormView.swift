//
//  ContactFormView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import MessageUI
import UIKit

struct ContactFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var contentFilter = ContentFilterManager.shared
    
    @State private var subject = ""
    @State private var message = ""
    @State private var showMailComposer = false
    @State private var showContentWarning = false
    @State private var contentWarningMessage = ""
    @State private var isSending = false
    @State private var mailDelegate = MailComposeDelegate()
    
    private let recipientEmail = "tobiadegoroye49@gmail.com"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ModernTextField(
                        title: "Subject",
                        text: $subject,
                        icon: "text.bubble",
                        isRequired: true
                    )
                } header: {
                    Text("Subject")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $message)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .scrollContentBackground(.hidden)
                            .frame(height: 300)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                } header: {
                    Text("Message")
                } footer: {
                    Text("Please describe your feedback, issue, or feature request.")
                }
                
                Section {
                    Button {
                        sendEmail()
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isSending ? "Sending..." : "Send Email")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            (subject.isEmpty || message.isEmpty) ? Color.gray : Color.blue
                        )
                        .cornerRadius(12)
                    }
                    .disabled(subject.isEmpty || message.isEmpty || isSending)
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
                if MFMailComposeViewController.canSendMail() {
                    MailComposeView(
                        recipientEmail: recipientEmail,
                        subject: subject,
                        body: message,
                        isPresented: $showMailComposer
                    ) {
                        isSending = false
                        dismiss()
                    }
                } else {
                    // Fallback view if mail is not configured
                    VStack {
                        Text("Mail Not Configured")
                            .font(.headline)
                            .padding()
                        Text("Please configure Mail in Settings or use the Quick Email option.")
                            .padding()
                        Button("OK") {
                            showMailComposer = false
                        }
                    }
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
        
        isSending = true
        
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
        } else {
            // Open Mail app with mailto URL
            let subjectEncoded = filteredSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = filteredMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
                UIApplication.shared.open(url)
                isSending = false
                dismiss()
            } else {
                isSending = false
            }
        }
    }
}

#Preview {
    ContactFormView()
}

