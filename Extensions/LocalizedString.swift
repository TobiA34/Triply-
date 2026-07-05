//
//  LocalizedString.swift
//  Itinero
//
//  Extension for easy localization
//

import Foundation
import SwiftUI

extension String {
    /// Supported app language codes (must match Localizable_<code>.strings and SupportedLanguage).
    private static let supportedLanguageCodes: Set<String> = ["en", "es", "fr", "de", "it", "pt", "ja", "ko", "zh-Hans"]
    
    /// Resolves the device locale to a supported app language code.
    /// Uses: 1) iPhone preferred language (e.g. Spanish in Spain → es), 2) region fallback (e.g. Region Spain → es).
    private static func deviceLanguageCode() -> String {
        // 1) Primary: first preferred language (e.g. "es-ES", "es-MX", "fr-FR" → es, fr)
        if let preferred = Locale.preferredLanguages.first, !preferred.isEmpty {
            let code = languageCode(from: preferred)
            if supportedLanguageCodes.contains(code) { return code }
        }
        // 2) Fallback: current locale language (e.g. Locale.current from region)
        if let current = Locale.current.language.languageCode?.identifier {
            let code = languageCode(from: current)
            if supportedLanguageCodes.contains(code) { return code }
        }
        // 3) Region-based: infer from device region (e.g. Spain → Spanish, France → French)
        if let region = Locale.current.region?.identifier {
            let code = languageCodeFromRegion(region)
            if supportedLanguageCodes.contains(code) { return code }
        }
        return "en"
    }
    
    /// Parses a locale identifier (e.g. "es-ES", "zh-Hans-US") into our app language code.
    private static func languageCode(from localeIdentifier: String) -> String {
        let parts = localeIdentifier.split(separator: "-").map(String.init)
        let lang = parts.first ?? "en"
        if lang == "zh" {
            if parts.count > 1, parts[1].lowercased() == "hans" { return "zh-Hans" }
            if parts.count > 1, ["cn", "hans"].contains(parts[1].lowercased()) { return "zh-Hans" }
            return "zh-Hans"
        }
        return lang
    }
    
    /// Maps a region code (e.g. ES, FR, MX) to a supported language code when language list didn't match.
    private static func languageCodeFromRegion(_ region: String) -> String {
        let r = region.uppercased()
        switch r {
        case "ES", "MX", "AR", "CO", "CL", "PE", "VE", "EC", "GT", "CU", "BO", "DO", "HN", "PY", "SV", "UY", "CR", "PA", "NI": return "es"
        case "FR", "BE", "CA", "CH", "LU", "MC", "SN", "CI": return "fr"
        case "DE", "AT", "CH", "LI", "LU": return "de"
        case "IT", "CH", "SM", "VA": return "it"
        case "PT", "BR", "AO", "MZ": return "pt"
        case "JP": return "ja"
        case "KR": return "ko"
        case "CN", "SG", "TW": return "zh-Hans"
        case "GB", "US", "AU", "CA", "IE", "NZ", "ZA", "IN": return "en"
        default: return "en"
        }
    }
    
    /// Returns a localized string using the device language (no dropdown override).
    /// Loads from Localizable_<lang>.strings (e.g. Localizable_fr.strings) or .lproj bundles, then Localizable.strings.
    var localized: String {
        let languageCode = String.deviceLanguageCode()
        
        // 1) Try language-specific .lproj bundle (e.g. fr.lproj/Localizable.strings)
        if languageCode != "en",
           let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let langBundle = Bundle(path: lprojPath) {
            let value = langBundle.localizedString(forKey: self, value: nil, table: "Localizable")
            if value != self { return value }
        }
        
        // 2) Try language-specific table file (e.g. Localizable_fr.strings)
        if languageCode != "en",
           let path = Bundle.main.path(forResource: "Localizable_\(languageCode)", ofType: "strings"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String],
           let value = dict[self] {
            return value
        }
        
        // 3) Try base Localizable.strings (English)
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String],
           let value = dict[self] {
            return value
        }
        
        // 4) NSLocalizedString fallback
        let fallback = NSLocalizedString(self, comment: "")
        if fallback != self { return fallback }
        
        return self
    }
    
    /// Returns a localized string with arguments
    /// Thread-safe: UserDefaults is thread-safe for reading
    func localized(_ arguments: CVarArg...) -> String {
        let format = self.localized
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
                // Force refresh when language changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .themeChanged)) { _ in
                // Force refresh when theme changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
            }
            .onChange(of: themeManager.currentTheme) { _, _ in
                // Force refresh when theme changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
            }
            .onChange(of: themeManager.defaultPalette) { _, _ in
                // Force refresh when default palette changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
            }
            .onChange(of: themeManager.activeCustomThemeID) { _, _ in
                // Force refresh when custom theme changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
            }
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Force refresh when language changes - defer to avoid publishing during view updates
                Task { @MainActor in
                refreshID = UUID()
                }
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

