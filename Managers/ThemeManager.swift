//
//  ThemeManager.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case custom = "Custom"
    
    var isCustom: Bool { self == .custom }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil  // Use system appearance
        case .light: return .light
        case .dark: return .dark
        case .custom: return nil  // Use system for custom palette
        }
    }
}

enum DefaultPalette: String, CaseIterable, Identifiable {
    case warm
    case classic
    case ocean
    case forest
    case sunset
    case midnight
    
    var id: String { rawValue }
    var title: String {
        switch self {
        case .warm: return "Sky"
        case .classic: return "Classic"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        case .midnight: return "Midnight"
        }
    }
    
    func palette(for scheme: ColorScheme) -> CustomTheme.Palette {
        let isDark = scheme == .dark
        switch self {
        case .warm:
            return isDark
                ? .init(accent: Color(red: 0.45, green: 0.72, blue: 1.0), background: Color(red: 0.09, green: 0.11, blue: 0.16), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: Color(red: 0.22, green: 0.52, blue: 0.96), background: Color(red: 0.95, green: 0.97, blue: 1.0), text: Color(red: 0.1, green: 0.14, blue: 0.22), secondaryText: Color(red: 0.42, green: 0.48, blue: 0.55))
        case .classic:
            return isDark
                ? .init(accent: .blue, background: Color(red: 0.11, green: 0.11, blue: 0.12), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: .blue, background: .white, text: .primary, secondaryText: .secondary)
        case .ocean:
            return isDark
                ? .init(accent: .teal, background: Color(red: 0.08, green: 0.12, blue: 0.18), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: .teal, background: Color(red: 0.95, green: 0.98, blue: 1.0), text: .black, secondaryText: .gray)
        case .forest:
            return isDark
                ? .init(accent: .green, background: Color(red: 0.08, green: 0.14, blue: 0.10), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: .green, background: Color(red: 0.95, green: 0.99, blue: 0.96), text: .black, secondaryText: .gray)
        case .sunset:
            return isDark
                ? .init(accent: .orange, background: Color(red: 0.18, green: 0.10, blue: 0.08), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: .orange, background: Color(red: 1.0, green: 0.97, blue: 0.95), text: .black, secondaryText: .gray)
        case .midnight:
            return isDark
                ? .init(accent: .indigo, background: Color(red: 0.09, green: 0.09, blue: 0.14), text: .white, secondaryText: Color(.systemGray2))
                : .init(accent: .indigo, background: Color(red: 0.95, green: 0.95, blue: 0.98), text: .black, secondaryText: .gray)
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var customAccentColor: Color? = nil
    
    // Custom themes
    @Published private(set) var customThemes: [CustomTheme] = []
    @Published var activeCustomThemeID: UUID?
    @Published var userTier: UserTier = .free
    @Published var defaultPalette: DefaultPalette = .classic
    
    // Computed palette considering theme selection - thread-safe with fallback
    var currentPalette: CustomTheme.Palette {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            // Fallback palette if accessed from wrong thread
            return defaultPalette.palette(for: .light)
        }
        
        // Try custom theme first
        if currentTheme.isCustom, let activeID = activeCustomThemeID {
            if let theme = customThemes.first(where: { $0.id == activeID }) {
                return theme.palette
            }
            // If custom theme not found, fall back to default
        }
        
        // Use selected default palette
        let base = defaultPalette.palette(for: resolvedColorScheme)
        return CustomTheme.Palette(
            accent: customAccentColor ?? base.accent, // user default accent dominates if set
            background: base.background,
            text: base.text,
            secondaryText: base.secondaryText
        )
    }
    
    private var resolvedColorScheme: ColorScheme {
        switch currentTheme {
        case .dark: return .dark
        case .light: return .light
        case .system:
            #if canImport(UIKit)
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            #else
            return .light
            #endif
        case .custom:
            #if canImport(UIKit)
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            #else
            return .light
            #endif
        }
    }
    
    private let themeKey = "app_theme"
    private let accentColorKey = "accent_color_v2"
    private let activeCustomThemeKey = "active_custom_theme_id"
    private let userTierKey = "user_tier"
    private let defaultPaletteKey = "default_palette_v2"
    
    private init() {
        loadTheme()
    }
    
    func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        if let colorData = UserDefaults.standard.data(forKey: accentColorKey),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            customAccentColor = Color(color)
        }
        
        if let savedTier = UserDefaults.standard.string(forKey: userTierKey),
           let tier = UserTier(rawValue: savedTier) {
            userTier = tier
        }
        
        if let idString = UserDefaults.standard.string(forKey: activeCustomThemeKey),
           let uuid = UUID(uuidString: idString) {
            activeCustomThemeID = uuid
        }
        
        if let savedPalette = UserDefaults.standard.string(forKey: defaultPaletteKey),
           let p = DefaultPalette(rawValue: savedPalette) {
            defaultPalette = p
        }
        
        // Load custom themes from database if available
        reloadCustomThemes()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
        objectWillChange.send()
        // Force immediate UI update
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
    
    func setAccentColor(_ color: Color) {
        customAccentColor = color
        let uiColor = color.toUIColor()
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: accentColorKey)
        }
        objectWillChange.send()
        // Force immediate UI update
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
    
    func setUserTier(_ tier: UserTier) {
        userTier = tier
        UserDefaults.standard.set(tier.rawValue, forKey: userTierKey)
    }
    
    func setDefaultPalette(_ palette: DefaultPalette) {
        defaultPalette = palette
        UserDefaults.standard.set(palette.rawValue, forKey: defaultPaletteKey)
        objectWillChange.send()
        // Force immediate UI update
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
    
    func reloadCustomThemes() {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.reloadCustomThemes()
            }
            return
        }
        
        guard let context = DatabaseManager.shared.mainContext else {
            customThemes = []
            return
        }
        
        let descriptor = FetchDescriptor<CustomTheme>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        if let results = try? context.fetch(descriptor) {
            customThemes = results
            objectWillChange.send()
        } else {
            customThemes = []
        }
    }
    
    func createOrUpdateTheme(
        id: UUID? = nil,
        name: String,
        accent: Color,
        background: Color,
        text: Color,
        secondaryText: Color
    ) -> CustomTheme? {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            var result: CustomTheme?
            DispatchQueue.main.sync {
                result = createOrUpdateTheme(id: id, name: name, accent: accent, background: background, text: text, secondaryText: secondaryText)
            }
            return result
        }
        
        guard let context = DatabaseManager.shared.mainContext else { return nil }
        
        // Enforce tier limits on creation
        if id == nil, let max = userTier.maxCustomThemes, customThemes.count >= max {
            return nil
        }
        
        let accentHex = accent.hexRGBA
        let backgroundHex = background.hexRGBA
        let textHex = text.hexRGBA
        let secondaryTextHex = secondaryText.hexRGBA
        
        if let id = id, let existing = customThemes.first(where: { $0.id == id }) {
            existing.name = name
            existing.accentHex = accentHex
            existing.backgroundHex = backgroundHex
            existing.textHex = textHex
            existing.secondaryTextHex = secondaryTextHex
            existing.updatedAt = Date()
            try? context.save()
            reloadCustomThemes()
            objectWillChange.send()
            NotificationCenter.default.post(name: .themeChanged, object: nil)
            return existing
        } else {
            let theme = CustomTheme(
                name: name,
                accentHex: accentHex,
                backgroundHex: backgroundHex,
                textHex: textHex,
                secondaryTextHex: secondaryTextHex
            )
            context.insert(theme)
            try? context.save()
            reloadCustomThemes()
            objectWillChange.send()
            NotificationCenter.default.post(name: .themeChanged, object: nil)
            return theme
        }
    }
    
    func deleteTheme(id: UUID) {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.deleteTheme(id: id)
            }
            return
        }
        
        guard let context = DatabaseManager.shared.mainContext else { return }
        if let theme = customThemes.first(where: { $0.id == id }) {
            context.delete(theme)
            try? context.save()
            if activeCustomThemeID == id {
                activeCustomThemeID = nil
                UserDefaults.standard.removeObject(forKey: activeCustomThemeKey)
            }
            reloadCustomThemes()
            objectWillChange.send()
            NotificationCenter.default.post(name: .themeChanged, object: nil)
        }
    }
    
    func selectCustomTheme(id: UUID?) {
        activeCustomThemeID = id
        UserDefaults.standard.set(id?.uuidString, forKey: activeCustomThemeKey)
        if id != nil {
            setTheme(.custom)
        }
        objectWillChange.send()
        // Force immediate UI update
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }
}

// Helper to convert SwiftUI Color to UIColor for storage
extension Color {
    func toUIColor() -> UIColor {
        let uiColor = UIColor(self)
        return uiColor
    }
}

// MARK: - Design System (spacing, radius, animation for consistent UI/UX)
enum DesignSystem {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let card: CGFloat = 20
        static let pill: CGFloat = 100
    }
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.72)
    }
    enum Shadow {
        static func card(opacity: Double = 0.08) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(opacity), 14, 0, 6)
        }
        static func cardSubtle(opacity: Double = 0.05) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (Color.black.opacity(opacity), 6, 0, 2)
        }
    }
}
