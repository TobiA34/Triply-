//
//  ThemeDefaultsView.swift
//  Triply
//
//  Created on 2025
//

import SwiftUI

struct ThemeDefaultsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var selectedPalette: DefaultPalette
    @State private var accent: Color
    
    init() {
        _selectedPalette = State(initialValue: ThemeManager.shared.defaultPalette)
        _accent = State(initialValue: ThemeManager.shared.customAccentColor)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Default Palette")) {
                Picker("Palette", selection: $selectedPalette) {
                    ForEach(DefaultPalette.allCases) { palette in
                        HStack(spacing: 12) {
                            Text(palette.title)
                            Spacer()
                            palettePreview(palette)
                        }
                        .tag(palette)
                    }
                }
            }
            Section(header: Text("Default Accent")) {
                ColorPicker("Accent Color", selection: $accent, supportsOpacity: true)
            }
            Section(header: Text("Preview")) {
                let preview = selectedPalette.palette(for: .light)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Buttons & Accents")
                        .foregroundColor(preview.text)
                    Button("Primary") {}
                        .buttonStyle(.borderedProminent)
                        .tint(accent)
                    Button("Secondary") {}
                        .buttonStyle(.bordered)
                        .tint(accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(preview.background)
                .cornerRadius(12)
            }
        }
        .navigationTitle("Theme Defaults")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    themeManager.setDefaultPalette(selectedPalette)
                    themeManager.setAccentColor(accent)
                    dismiss()
                }
            }
        }
    }
    
    private func palettePreview(_ palette: DefaultPalette) -> some View {
        let light = palette.palette(for: .light)
        return HStack(spacing: 4) {
            Circle().fill(light.accent).frame(width: 10, height: 10)
            Circle().fill(light.background).frame(width: 10, height: 10).overlay(Circle().stroke(Color.gray.opacity(0.2)))
            Circle().fill(light.text).frame(width: 10, height: 10)
            Circle().fill(light.secondaryText).frame(width: 10, height: 10)
        }
    }
}

#Preview {
    NavigationStack {
        ThemeDefaultsView()
    }
}


