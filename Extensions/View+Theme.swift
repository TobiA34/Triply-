//
//  View+Theme.swift
//  Itinero
//
//  View modifiers for applying themes throughout the app
//

import SwiftUI

extension View {
    /// Applies theme background color
    func themeBackground() -> some View {
        self.modifier(ThemeBackgroundModifier())
    }
    
    /// Applies theme text color
    func themeText() -> some View {
        self.modifier(ThemeTextModifier())
    }
    
    /// Applies theme accent color
    func themeAccent() -> some View {
        self.modifier(ThemeAccentModifier())
    }
}


// Background color modifier
struct ThemeBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.currentPalette.background)
    }
}

// Text color modifier
struct ThemeTextModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(themeManager.currentPalette.text)
    }
}

// Accent color modifier
struct ThemeAccentModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .tint(themeManager.currentPalette.accent)
    }
}

// Helper for themed buttons
extension Button {
    func themedButton(style: ThemedButtonStyle = .primary) -> some View {
        self.modifier(ThemedButtonModifier(style: style))
    }
}

enum ThemedButtonStyle {
    case primary
    case secondary
    case outline
}

struct ThemedButtonModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    let style: ThemedButtonStyle
    
    private var palette: CustomTheme.Palette {
        themeManager.currentPalette
    }
    
    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .buttonStyle(.borderedProminent)
                .tint(palette.accent)
        case .secondary:
            content
                .buttonStyle(.bordered)
                .foregroundColor(palette.accent)
        case .outline:
            content
                .buttonStyle(.bordered)
                .foregroundColor(palette.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(palette.accent, lineWidth: 1)
                )
        }
    }
}

// Helper for themed cards
extension View {
    func themedCard() -> some View {
        self.modifier(ThemedCardModifier())
    }
}

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    private var palette: CustomTheme.Palette {
        themeManager.currentPalette
    }
    
    func body(content: Content) -> some View {
        content
            .background(palette.background.opacity(0.8))
            .foregroundColor(palette.text)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Shared Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}