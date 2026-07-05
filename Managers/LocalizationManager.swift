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
    
    // Bundle for current language - thread-safe
    var bundle: Bundle {
        return Bundle.main
    }
    
    private init() {
        currentLanguage = .english
        loadLanguage()
    }
    
    /// Resolves device locale (language + region) to SupportedLanguage. Matches LocalizedString.deviceLanguageCode logic.
    private static func deviceLanguage() -> SupportedLanguage {
        let code = Self.resolveDeviceLanguageCode()
        return SupportedLanguage(rawValue: code) ?? .english
    }
    
    /// Returns the same language code used by LocalizedString (preferred language, then region fallback).
    static func resolveDeviceLanguageCode() -> String {
        if let preferred = Locale.preferredLanguages.first, !preferred.isEmpty {
            let code = languageCode(from: preferred)
            if SupportedLanguage(rawValue: code) != nil { return code }
        }
        if let current = Locale.current.language.languageCode?.identifier {
            let code = languageCode(from: current)
            if SupportedLanguage(rawValue: code) != nil { return code }
        }
        if let region = Locale.current.region?.identifier {
            let code = languageCodeFromRegion(region)
            if SupportedLanguage(rawValue: code) != nil { return code }
        }
        return "en"
    }
    
    private static func languageCode(from localeIdentifier: String) -> String {
        let parts = localeIdentifier.split(separator: "-").map(String.init)
        let lang = parts.first ?? "en"
        if lang == "zh" { return "zh-Hans" }
        return lang
    }
    
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
    
    /// Syncs currentLanguage from device (language follows device, no manual override).
    func loadLanguage() {
        currentLanguage = Self.deviceLanguage()
    }
    
    /// No-op: app language follows device only. Kept for API compatibility (e.g. LanguageSelectionView).
    func setLanguage(_ language: SupportedLanguage) {
        loadLanguage()
    }
    
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
    static let themeChanged = Notification.Name("themeChanged")
}

