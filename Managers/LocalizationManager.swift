//
//  LocalizationManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import SwiftUI

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh-Hans"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "中文"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .chinese: return "简体中文"
        }
    }
}

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: SupportedLanguage = .english
    
    private let languageKey = "app_language"
    
    // Bundle for current language - thread-safe
    var bundle: Bundle {
        // Always use main bundle for now since we don't have separate language bundles
        // The localized extension handles language switching via UserDefaults
        return Bundle.main
    }
    
    private init() {
        // Initialize safely
        currentLanguage = .english // Default first
        loadLanguage()
    }
    
    func loadLanguage() {
        // Safely load language from UserDefaults
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           let language = SupportedLanguage(rawValue: savedLanguage) {
            currentLanguage = language
        } else {
            // Detect system language safely
            if let systemLanguageCode = Locale.current.language.languageCode?.identifier,
               let systemLanguage = SupportedLanguage(rawValue: systemLanguageCode) {
                currentLanguage = systemLanguage
            } else {
                currentLanguage = .english
            }
        }
    }
    
    func setLanguage(_ language: SupportedLanguage) {
        guard currentLanguage != language else { return }
        
        // Update UserDefaults first (thread-safe)
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        UserDefaults.standard.synchronize()
        
        // Update current language immediately on main thread
        currentLanguage = language
        
        // Force UI update by sending notification
        NotificationCenter.default.post(name: .languageChanged, object: nil)
        
        // Also trigger objectWillChange to ensure all observers update
        objectWillChange.send()
        
        print("🌐 Language changed to: \(language.rawValue)")
    }
    
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
    static let themeChanged = Notification.Name("themeChanged")
}

