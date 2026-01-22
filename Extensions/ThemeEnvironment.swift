//
//  ThemeEnvironment.swift
//  Itinero
//
//  New robust theme system using Environment values
//

import SwiftUI

// MARK: - Theme Environment Key
private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue: CustomTheme.Palette = CustomTheme.Palette(
        accent: .blue,
        background: .white,
        text: .primary,
        secondaryText: .secondary
    )
}

extension EnvironmentValues {
    var themePalette: CustomTheme.Palette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}

// MARK: - Theme View Modifier
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    @State private var currentPalette: CustomTheme.Palette = CustomTheme.Palette(
        accent: .blue,
        background: .white,
        text: .primary,
        secondaryText: .secondary
    )
    
    func body(content: Content) -> some View {
        content
            .environment(\.themePalette, currentPalette)
            .tint(currentPalette.accent)
            .foregroundStyle(currentPalette.text)
            .scrollContentBackground(.hidden)
            .background(currentPalette.background)
            .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
                // Force update when theme changes
                currentPalette = themeManager.currentPalette
            }
            .onChange(of: themeManager.currentPalette) { oldValue, newValue in
                // Direct observation - update state immediately
                currentPalette = newValue
            }
            .onAppear {
                // Initialize on appear
                currentPalette = themeManager.currentPalette
            }
    }
}

extension View {
    /// Apply theme to view - use this instead of applyAppTheme()
    func applyTheme(themeManager: ThemeManager) -> some View {
        self.modifier(ThemeModifier(themeManager: themeManager))
    }
}

// MARK: - Theme Helper Views
struct ThemedBackground: View {
    @Environment(\.themePalette) var palette
    
    var body: some View {
        palette.background
            .ignoresSafeArea(.all)
    }
}

struct ThemedText: ViewModifier {
    @Environment(\.themePalette) var palette
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(palette.text)
    }
}

struct ThemedSecondaryText: ViewModifier {
    @Environment(\.themePalette) var palette
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(palette.secondaryText)
    }
}

extension View {
    func themedText() -> some View {
        self.modifier(ThemedText())
    }
    
    func themedSecondaryText() -> some View {
        self.modifier(ThemedSecondaryText())
    }
}
