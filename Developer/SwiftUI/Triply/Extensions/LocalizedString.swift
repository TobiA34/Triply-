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
        // UserDefaults is thread-safe for reading, so we can access it directly
        let languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        
        // Always use main bundle's Localizable.strings for now
        // The main bundle contains the base English strings
        let mainBundleString = NSLocalizedString(self, comment: "")
        
        // If translation found in main bundle, return it
        if mainBundleString != self {
            return mainBundleString
        }
        
        // If we have a language bundle for the selected language, try it
        if languageCode != "en" {
            if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                let localizedString = bundle.localizedString(forKey: self, value: nil, table: nil)
                // Only return if we got a different string (translation found)
                if localizedString != self {
                    return localizedString
                }
            }
        }
        
        // Fallback: return the key itself if no translation found
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
        let manager = ThemeManager.shared
        return self
            .tint(manager.currentPalette.accent)
            .foregroundStyle(manager.currentPalette.text)
            .background(manager.currentPalette.background.ignoresSafeArea())
            .id(themeRefreshID(from: manager))
    }
    
    private func themeRefreshID(from manager: ThemeManager) -> String {
        let themeKey = manager.currentTheme.rawValue
        let customID = manager.activeCustomThemeID?.uuidString ?? "none"
        let paletteKey = [
            manager.currentPalette.accent.hexRGBA,
            manager.currentPalette.background.hexRGBA,
            manager.currentPalette.text.hexRGBA,
            manager.currentPalette.secondaryText.hexRGBA
        ].joined(separator: "|")
        return themeKey + ":" + customID + ":" + paletteKey
    }
}

