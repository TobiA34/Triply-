//
//  View+Localization.swift
//  Itinero
//
//  View modifier to refresh views when language changes
//

import SwiftUI

extension View {
    /// Refreshes the view when language changes
    func refreshOnLanguageChange() -> some View {
        self.modifier(LanguageChangeModifier())
    }
}

struct LanguageChangeModifier: ViewModifier {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var refreshID = UUID()
    
    func body(content: Content) -> some View {
        content
            .id(refreshID)
            .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                // Force view refresh when language changes with smooth animation
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
            .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
                // Force refresh when language changes
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
    }
}

