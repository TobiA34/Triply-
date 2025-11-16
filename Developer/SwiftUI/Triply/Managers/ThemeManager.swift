//
//  ThemeManager.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case custom = "Custom"
    
    var isCustom: Bool { self == .custom }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return .light // Force light mode
        case .light: return .light
        case .custom: return .light // Force light mode for custom themes too
        }
    }
}

enum DefaultPalette: String, CaseIterable, Identifiable {
    case classic
    case ocean
    case forest
    case sunset
    case midnight
    
    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: return "Classic"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .sunset: return "Sunset"
        case .midnight: return "Midnight"
        }
    }
    
    func palette(for scheme: ColorScheme) -> CustomTheme.Palette {
        // Always use light mode colors
        switch self {
        case .classic:
            return .init(accent: .blue, background: .white, text: .primary, secondaryText: .secondary)
        case .ocean:
            return .init(accent: .teal, background: Color(red: 0.95, green: 0.98, blue: 1.0), text: .black, secondaryText: .gray)
        case .forest:
            return .init(accent: .green, background: Color(red: 0.95, green: 0.99, blue: 0.96), text: .black, secondaryText: .gray)
        case .sunset:
            return .init(accent: .orange, background: Color(red: 1.0, green: 0.97, blue: 0.95), text: .black, secondaryText: .gray)
        case .midnight:
            // Keep dark for midnight theme but force light mode
            return .init(accent: .indigo, background: Color(red: 0.95, green: 0.95, blue: 0.98), text: .black, secondaryText: .gray)
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var customAccentColor: Color = .blue
    
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
            accent: customAccentColor, // user default accent dominates
            background: base.background,
            text: base.text,
            secondaryText: base.secondaryText
        )
    }
    
    private var resolvedColorScheme: ColorScheme {
        // Always return light mode
        return .light
    }
    
    private let themeKey = "app_theme"
    private let accentColorKey = "accent_color"
    private let activeCustomThemeKey = "active_custom_theme_id"
    private let userTierKey = "user_tier"
    private let defaultPaletteKey = "default_palette"
    
    private init() {
        loadTheme()
    }
    
    func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey) {
            // Migrate old dark mode preference to light mode
            if savedTheme == "Dark" {
                currentTheme = .light
                UserDefaults.standard.set("Light", forKey: themeKey)
            } else if let theme = AppTheme(rawValue: savedTheme) {
                currentTheme = theme
            } else {
                currentTheme = .light // Default to light
            }
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

