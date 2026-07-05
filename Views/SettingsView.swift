//
//  SettingsView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import MessageUI
import UIKit
import RevenueCat

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    private let settingsManager = SettingsManager.shared
    
    // Check if presented as sheet/modal
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedCurrency: Currency = Currency.currency(for: "USD")
    @ObservedObject private var iapManager = IAPManager.shared
    @State private var showPaywall = false
    
    // Use an explicit init so the sheet doesn't trigger extra loads on appear.
    // Values are pulled from the shared managers that are already initialized
    // in TripListView / app startup, so presenting the modal is cheap and stable.
    init() {
        let settings = SettingsManager.shared
        _selectedCurrency = State(initialValue: settings.currentCurrency)
    }
    
    var body: some View {
        Form {
            proSection
            currencySection
            featureRequestsSection
            aboutSection
            contactSection
        }
        // Local keyboard handling so taps on rows stay responsive
        .keyboardDismissable(
            onTap: false,
            onDrag: true,
            showDoneButton: true
        )
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear {
            // Auto-save when leaving settings (when in tab bar)
            saveSettings()
        }
    }
    
    // Computed property to ensure theme background reactivity
    private var themeBackgroundColor: Color {
        return themeManager.currentPalette.background
    }
    
    private var preferencesSection: some View {
        Section {
            preferenceRow(
                icon: settingsManager.currencyIconName(),
                color: .green,
                title: "Currency"
            )
        } header: {
            Text("Preferences")
        } footer: {
            Text("Customize your app experience with currency and theme settings.")
        }
    }
    
    private func preferenceRow(icon: String, color: Color, title: String) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private var currencySection: some View {
        Section {
            NavigationLink {
                CurrencySelectionView(selectedCurrency: $selectedCurrency)
            } label: {
                HStack(spacing: 12) {
                    settingsIcon("dollarsign.circle.fill", background: .green)
                    Text("Currency")
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(selectedCurrency.symbol) \(selectedCurrency.code)")
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink(destination: CurrencyConverterView()) {
                HStack(spacing: 12) {
                    settingsIcon("arrow.left.arrow.right", background: .orange)
                    Text("Currency Converter")
                        .foregroundColor(.primary)
                }
            }
        } header: {
            Text("Preferences")
        }
    }
    
    private var previewSection: some View {
        Section {
            HStack {
                Text("Current Selection")
                    .foregroundColor(Color(white: 0.4))
                Spacer()
                HStack(spacing: 8) {
                    Text(selectedCurrency.symbol)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(selectedCurrency.code)
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.4))
                }
            }
            
            HStack {
                Text("Example")
                    .foregroundColor(Color(white: 0.4))
                Spacer()
                Text("\(selectedCurrency.symbol)\(String(format: "%.2f", 1000.0))")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        } header: {
            Text("Preview")
        }
    }
    
    private var featureRequestsSection: some View {
        Section {
            NavigationLink {
                FeatureRequestsView()
            } label: {
                HStack(spacing: 12) {
                    settingsIcon("lightbulb.fill", background: .yellow)
                    Text("Feature Requests")
                        .foregroundColor(.primary)
                }
            }
        } header: {
            Text("Feedback")
        } footer: {
            Text("Request features and vote on what you'd like to see next!")
        }
    }
    
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    settingsIcon("info.circle.fill", background: .blue)
                    Text("About Itinero")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—") (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"))")
                    .font(.subheadline)
                    .foregroundColor(Color(white: 0.4))
                
                Text("Plan your trips with ease. Organize destinations, create itineraries, and track your budget all in one place.")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.4))
                    .padding(.top, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("App Information")
        }
    }
    
    private var contactSection: some View {
        Section {
            NavigationLink {
                InlineContactSupportView()
            } label: {
                HStack(spacing: 12) {
                    settingsIcon("envelope.fill", background: .blue)
                    Text("Contact Support")
                        .foregroundColor(.primary)
                }
            }
            
            NavigationLink {
                QuickFeedbackView()
            } label: {
                HStack(spacing: 12) {
                    settingsIcon("paperplane.fill", background: .green)
                    Text("Quick Feedback")
                        .foregroundColor(.primary)
                }
            }
        } header: {
            Text("Contact")
        } footer: {
            Text("Send feedback, report issues, or request features")
        }
    }
    
    private var proSection: some View {
        Section {
            if iapManager.isPro {
                HStack(spacing: 12) {
                    settingsIcon("crown.fill", background: .yellow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Itinero Pro")
                            .foregroundColor(.primary)
                        Text("Subscription active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            } else {
                Button {
                    Task {
                        if await iapManager.preparePaywall() {
                            showPaywall = true
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        settingsIcon("crown.fill", background: .purple)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Itinero Pro")
                                .foregroundColor(.primary)
                            Text(proBenefitLine)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(white: 0.7))
                    }
                }
                .accessibilityIdentifier("upgrade_pro")
            }

            Button {
                Task { await iapManager.restorePurchases() }
            } label: {
                HStack(spacing: 12) {
                    settingsIcon("arrow.clockwise", background: .blue)
                    Text("Restore Purchases")
                        .foregroundColor(.primary)
                }
            }

            Link(destination: IAPManager.termsOfUseURL) {
                HStack(spacing: 12) {
                    settingsIcon("doc.text.fill", background: .gray)
                    Text("Terms of Use")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.7))
                }
            }

            Link(destination: IAPManager.privacyPolicyURL) {
                HStack(spacing: 12) {
                    settingsIcon("hand.raised.fill", background: .gray)
                    Text("Privacy Policy")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.7))
                }
            }
        } header: {
            Text("Itinero Pro")
        } footer: {
            if let info = iapManager.lastInfoMessage {
                Text(info)
            } else if let error = iapManager.lastErrorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var proBenefitLine: String {
        if let package = iapManager.currentOffering?.availablePackages.first {
            return "Unlimited trips & Instagram import · from \(package.localizedPriceString)"
        }
        return "Unlimited trips, activities & more"
    }

    private func settingsIcon(_ systemName: String, background: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(background)
                .frame(width: 30, height: 30)
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private func resetSelections() {
        selectedCurrency = settingsManager.currentCurrency
    }
    
    private func saveSettings() {
        // Update currency in database
        settingsManager.updateCurrency(selectedCurrency, in: modelContext)
        settingsManager.currentCurrency = selectedCurrency
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
}


// Inline Contact Form - No dependencies, always works
private struct InlineContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var showMailComposer = false
    
    private let recipientEmail = "tobiadegoroye49@gmail.com"
    
    var body: some View {
            Form {
                Section {
                    TextField("Subject", text: $subject)
                        .textInputAutocapitalization(.sentences)
                        .onChange(of: subject) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                subject = oldValue
                            }
                        }
                } header: {
                    Text("Subject")
                }
                
                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 200)
                        .onChange(of: message) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                message = oldValue
                            }
                        }
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
                        .padding(.vertical, 12)
                        .background(
                        (subject.isEmpty || message.isEmpty) 
                                ? Color.gray.opacity(0.5) 
                                : Color.blue
                        )
                        .cornerRadius(10)
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
            InlineMailComposeView(
                recipientEmail: recipientEmail,
                subject: subject,
                body: message,
                isPresented: $showMailComposer
            ) {
                dismiss()
            }
        }
    }
    
    private func sendEmail() {
        guard !subject.isEmpty && !message.isEmpty else { return }
        
            if MFMailComposeViewController.canSendMail() {
                showMailComposer = true
            } else {
                // Fallback to mailto URL
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(recipientEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
            UIApplication.shared.open(url)
                dismiss()
            }
        }
    }
}

// Inline Mail Compose View - No external dependencies
private struct InlineMailComposeView: UIViewControllerRepresentable {
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
        Coordinator(isPresented: $isPresented, onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isPresented: Bool
        var onDismiss: (() -> Void)?
        
        init(isPresented: Binding<Bool>, onDismiss: (() -> Void)?) {
            _isPresented = isPresented
            self.onDismiss = onDismiss
        }
        
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            // Log the result
            switch result {
            case .sent:
                print("✅ Email sent successfully!")
            case .saved:
                print("📝 Email saved as draft")
            case .cancelled:
                print("❌ Email cancelled by user")
            case .failed:
                print("❌ Email failed to send: \(error?.localizedDescription ?? "Unknown error")")
            @unknown default:
                print("⚠️ Unknown mail compose result")
            }
            
            // Dismiss controller first (required)
            controller.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.onDismiss?()
                    }
                }
            }
        }
    }
}

// Quick Feedback View - Alternative approach using share sheet and clipboard
private struct QuickFeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedback = ""
    @State private var showShareSheet = false
    @State private var showSuccessAlert = false
    @State private var showCopyConfirmation = false
    
    private let recipientEmail = "tobiadegoroye49@gmail.com"
    
    var body: some View {
        Form {
            Section {
                TextEditor(text: $feedback)
                    .frame(minHeight: 200)
                    .overlay(
                        Group {
                            if feedback.isEmpty {
                                VStack {
                                    HStack {
                                        Text("Enter your feedback, issue, or feature request here...")
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 5)
                                            .padding(.top, 8)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            } header: {
                Text("Your Feedback")
            } footer: {
                Text("Your feedback helps us improve Itinero. All feedback is appreciated!")
            }
            
            Section {
                // Option 1: Share Sheet (works on all devices)
                Button {
                    shareFeedback()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Share Feedback")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(feedback.isEmpty)
                
                // Option 2: Copy to Clipboard
                Button {
                    copyToClipboard()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(.green)
                        Text("Copy Email Details")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(feedback.isEmpty)
                
                // Option 3: Open Mail App (if available)
                if MFMailComposeViewController.canSendMail() {
                    Button {
                        openMailComposer()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.orange)
                            Text("Open Mail App")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(feedback.isEmpty)
                }
            } header: {
                Text("Send Options")
            } footer: {
                Text("Choose how you'd like to send your feedback. Share opens your device's share menu, Copy saves email details to clipboard.")
            }
        }
        .navigationTitle("Quick Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            FeedbackShareSheet(items: [formattedEmailText()])
        }
        .alert("Copied!", isPresented: $showCopyConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Email details copied to clipboard. You can now paste it into your email app.")
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Your feedback has been shared successfully!")
        }
    }
    
    private func formattedEmailText() -> String {
        let subject = "Itinero Travel App - User Feedback"
        let body = """
        To: \(recipientEmail)
        Subject: \(subject)
        
        \(feedback)
        
        ---
        Sent from Itinero iOS App
        """
        return body
    }
    
    private func shareFeedback() {
        let text = formattedEmailText()
        showShareSheet = true
    }
    
    private func copyToClipboard() {
        let emailText = """
        To: \(recipientEmail)
        Subject: Itinero Travel App - User Feedback
        
        \(feedback)
        """
        UIPasteboard.general.string = emailText
        showCopyConfirmation = true
    }
    
    private func openMailComposer() {
        // This would open the mail composer
        // For now, we'll use the share sheet approach
        shareFeedback()
    }
}

// Feedback Share Sheet Helper
private struct FeedbackShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


// WishKit wrapper view that uses runtime availability check
private struct WishKitFeedbackView: View {
    var body: some View {
        WishKitNotAvailableView()
    }
}

// Fallback view when WishKit is not available
private struct WishKitNotAvailableView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("WishKit Not Linked")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The WishKit package needs to be properly linked in Xcode.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("To fix this in Xcode:")
                    .fontWeight(.semibold)
                
                Text("1. Select project → Itinero target")
                Text("2. Go to 'Package Dependencies' tab")
                Text("3. Verify 'wishkit-ios' is listed (version 4.7.0)")
                Text("4. If missing, click '+' and add:")
                Text("   https://github.com/wishkit/wishkit-ios.git")
                Text("5. File → Packages → Resolve Package Versions")
                Text("6. Product → Clean Build Folder (⇧⌘K)")
            }
            .font(.caption)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Text("The package is resolved but not linked to the target.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Feature Requests")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}



