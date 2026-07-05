import SwiftUI

struct InlineContactFormView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var canSend: Bool = false
    @State private var didSend: Bool = false

    private var background: Color {
        // Touch themeManager to ensure reactivity with currentPalette
        let _ = themeManager.currentTheme
        let _ = themeManager.defaultPalette
        let _ = themeManager.activeCustomThemeID
        let _ = themeManager.customThemes
        let _ = themeManager.customAccentColor
        return themeManager.currentPalette.background
    }

    var body: some View {
        formContent
            .navigationTitle("settings.contact".localized)
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(background)
            .onChange(of: name) { _, _ in validate() }
            .onChange(of: email) { _, _ in validate() }
            .onChange(of: message) { _, _ in validate() }
    }

    private var formContent: some View {
        Form {
            Section(header: Text("contact.yourInfo".localized)) {
                nameField
                emailField
            }
            Section(header: Text("settings.message".localized)) {
                messageField
            }
            Section {
                sendButton
            }
        }
    }

    private var nameField: some View {
        TextField("Name", text: $name)
            .textContentType(.name)
            .autocapitalization(.words)
            .onChange(of: name) { oldValue, newValue in
                if ContentFilter.containsBlockedContent(newValue) {
                    Task { @MainActor in name = oldValue }
                }
            }
    }

    private var emailField: some View {
        TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .onChange(of: email) { oldValue, newValue in
                if ContentFilter.containsBlockedContent(newValue) {
                    Task { @MainActor in email = oldValue }
                }
            }
    }

    private var messageField: some View {
        TextEditor(text: $message)
            .frame(minHeight: 150)
            .onChange(of: message) { oldValue, newValue in
                if ContentFilter.containsBlockedContent(newValue) {
                    Task { @MainActor in message = oldValue }
                }
            }
    }

    private var sendButton: some View {
        Button {
            didSend = true
            dismiss()
        } label: {
            Label("misc.send".localized, systemImage: "paperplane.fill")
        }
        .disabled(!isValid)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func validate() {
        canSend = isValid
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        // Simple validation regex suitable for basic checks
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    NavigationStack {
        InlineContactFormView()
            .environmentObject(ThemeManager.shared)
    }
}
