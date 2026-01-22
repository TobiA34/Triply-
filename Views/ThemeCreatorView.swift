//
//  ThemeCreatorView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI

struct ThemeCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    let editingTheme: CustomTheme?
    
    @State private var name: String
    @State private var accent: Color
    @State private var background: Color
    @State private var text: Color
    @State private var secondaryText: Color
    
    init(editingTheme: CustomTheme? = nil) {
        self.editingTheme = editingTheme
        _name = State(initialValue: editingTheme?.name ?? "My Theme")
        if let t = editingTheme {
            _accent = State(initialValue: Color(hex: t.accentHex) ?? .blue)
            _background = State(initialValue: Color(hex: t.backgroundHex) ?? .white)
            _text = State(initialValue: Color(hex: t.textHex) ?? .primary)
            _secondaryText = State(initialValue: Color(hex: t.secondaryTextHex) ?? .secondary)
        } else {
            _accent = State(initialValue: .blue)
            _background = State(initialValue: .white)
            _text = State(initialValue: .primary)
            _secondaryText = State(initialValue: .secondary)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Theme name", text: $name)
            }
            Section(header: Text("Colors")) {
                ColorPicker("Accent", selection: $accent, supportsOpacity: true)
                ColorPicker("Background", selection: $background, supportsOpacity: true)
                ColorPicker("Text", selection: $text, supportsOpacity: true)
                ColorPicker("Secondary Text", selection: $secondaryText, supportsOpacity: true)
            }
            
            Section(header: Text("Preview")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Title")
                        .font(.title2)
                        .foregroundColor(text)
                    Text("Secondary text and captions preview")
                        .font(.subheadline)
                        .foregroundColor(secondaryText)
                    Button("Primary Button") {}
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(background)
                .cornerRadius(12)
            }
        }
        .navigationTitle(editingTheme == nil ? "Create Theme" : "Edit Theme")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let updated = themeManager.createOrUpdateTheme(
                        id: editingTheme?.id,
                        name: name,
                        accent: accent,
                        background: background,
                        text: text,
                        secondaryText: secondaryText
                    )
                    if let theme = updated {
                        themeManager.selectCustomTheme(id: theme.id)
                        themeManager.setTheme(.custom)
                    }
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ThemeCreatorView()
    }
}


