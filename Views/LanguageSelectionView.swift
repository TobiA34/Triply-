//
//  LanguageSelectionView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import Foundation

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: SupportedLanguage
    @Environment(\.dismiss) var dismiss
    @State private var enhancedLanguage: EnhancedLanguage
    
    init(selectedLanguage: Binding<SupportedLanguage>) {
        self._selectedLanguage = selectedLanguage
        // Convert to EnhancedLanguage for the picker
        self._enhancedLanguage = State(initialValue: selectedLanguage.wrappedValue.enhanced)
    }
    
    var body: some View {
        LanguagePickerView(selectedLanguage: $enhancedLanguage)
            .onChange(of: enhancedLanguage) { oldValue, newValue in
                // Convert back to legacy SupportedLanguage when selection changes
                if let legacy = newValue.legacy {
                    selectedLanguage = legacy
                    // Immediately update the language manager - this triggers app-wide refresh
                    LocalizationManager.shared.setLanguage(legacy)
                    print("✅ Selected language: \(newValue.code) (\(newValue.nativeName))")
                } else {
                    // If not in legacy enum, try to find closest match
                    let database = LanguageDatabase.shared
                    if let closest = database.language(for: newValue.code)?.legacy {
                        selectedLanguage = closest
                        LocalizationManager.shared.setLanguage(closest)
                    }
                }
            }
            .onDisappear {
                // Ensure binding is updated when view disappears
                if let legacy = enhancedLanguage.legacy {
                    selectedLanguage = legacy
                    // Update language one more time to ensure it's saved
                    LocalizationManager.shared.setLanguage(legacy)
                }
            }
    }
}

#Preview {
    NavigationStack {
        LanguageSelectionView(selectedLanguage: .constant(.english))
    }
}

