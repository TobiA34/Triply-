//
//  LocalizedString.swift
//  Triply
//
//  Extension for easy localization
//

import Foundation
import SwiftUI

extension String {
    /// Returns a localized string using the current language from LocalizationManager
    /// Thread-safe: UserDefaults is thread-safe for reading
    var localized: String {
        // Get current language from UserDefaults
        let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        
        // Try to load from Localizable.strings file directly
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String],
           let value = dict[self] {
            return value
        }
        
        // Fallback: try NSLocalizedString (works with .lproj bundles if they exist)
        let localizedString = NSLocalizedString(self, comment: "")
        if localizedString != self {
            return localizedString
        }
        
        // Final fallback: return key itself
        return self
    }
    
    /// Returns a localized string with arguments
    /// Thread-safe: UserDefaults is thread-safe for reading
    func localized(_ arguments: CVarArg...) -> String {
        // UserDefaults is thread-safe for reading, so we can access it directly
        let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        
        // Get format string
        var format = NSLocalizedString(self, comment: "")
        
        // If we have a language bundle for the selected language, use it
        if languageCode != "en", let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let bundleString = bundle.localizedString(forKey: self, value: nil, table: nil)
            if bundleString != self {
                format = bundleString
            }
        }
        
        return String(format: format, arguments: arguments)
    }
}

// Note: Text extension removed to avoid infinite recursion
// Use Text("key".localized) directly instead of Text("key")

extension LocalizationManager {
    /// Get localized string for current language
    func string(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    /// Get localized string with format arguments
    func string(_ key: String, _ arguments: CVarArg...) -> String {
        let format = bundle.localizedString(forKey: key, value: nil, table: nil)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Theme Application
extension View {
    func applyAppTheme() -> some View {
        // Use environment objects to avoid crashes from singleton access
        return AppThemeWrapper(content: self)
    }
}

// Helper view to properly observe theme and language changes
private struct AppThemeWrapper<Content: View>: View {
    let content: Content
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var refreshID = UUID()
    
    // Safe palette access with fallback
    private var safePalette: CustomTheme.Palette {
        // Ensure we're on main thread and have valid palette
        guard Thread.isMainThread else {
            return CustomTheme.Palette(
                accent: .blue,
                background: .white,
                text: .primary,
                secondaryText: .secondary
            )
        }
        return themeManager.currentPalette
    }
    
    var body: some View {
        content
            .tint(safePalette.accent)
            .foregroundStyle(safePalette.text)
            .scrollContentBackground(.hidden) // Hide default Form/List backgrounds
            .id(refreshID)
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                // Force refresh when language changes
                refreshID = UUID()
            }
            .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
                // Force refresh when theme changes
                refreshID = UUID()
            }
            .onChange(of: themeManager.currentTheme) { _, _ in
                // Force refresh when theme changes
                refreshID = UUID()
            }
            .onChange(of: themeManager.defaultPalette) { _, _ in
                // Force refresh when default palette changes
                refreshID = UUID()
            }
            .onChange(of: themeManager.activeCustomThemeID) { _, _ in
                // Force refresh when custom theme changes
                refreshID = UUID()
            }
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force refresh when language changes
                refreshID = UUID()
            }
    }
}

// MARK: - Theme Color Helpers
extension ThemeManager {
    /// Get the current theme background color
    var themeBackground: Color {
        currentPalette.background
    }
    
    /// Get the current theme accent color
    var themeAccent: Color {
        currentPalette.accent
    }
    
    /// Get the current theme text color
    var themeText: Color {
        currentPalette.text
    }
    
    /// Get the current theme secondary text color
    var themeSecondaryText: Color {
        currentPalette.secondaryText
    }
}

