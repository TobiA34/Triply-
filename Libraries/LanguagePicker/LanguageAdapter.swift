//
//  LanguageAdapter.swift
//  Itinero
//
//  Adapter to bridge between old SupportedLanguage enum and new EnhancedLanguage
//

import Foundation

extension SupportedLanguage {
    /// Convert old SupportedLanguage to EnhancedLanguage
    var enhanced: EnhancedLanguage {
        let database = LanguageDatabase.shared
        return database.language(for: self.rawValue) ?? EnhancedLanguage(
            code: self.rawValue,
            name: self.displayName,
            nativeName: self.nativeName,
            flag: "🌐",
            region: .other
        )
    }
}

extension EnhancedLanguage {
    /// Convert EnhancedLanguage to old SupportedLanguage enum
    var legacy: SupportedLanguage? {
        SupportedLanguage(rawValue: self.code)
    }
}



