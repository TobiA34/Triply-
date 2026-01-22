//
//  View+ContentFilter.swift
//  Itinero
//
//  Extension to add content filtering to text fields
//

import SwiftUI

extension View {
    /// Adds content filtering to a text binding
    func contentFiltered(_ text: Binding<String>) -> some View {
        self.onChange(of: text.wrappedValue) { oldValue, newValue in
            if ContentFilter.containsBlockedContent(newValue) {
                text.wrappedValue = oldValue
            }
        }
    }
}

// Helper modifier for TextField
extension TextField {
    func withContentFilter() -> some View {
        self.onChange(of: self.text.wrappedValue) { oldValue, newValue in
            if ContentFilter.containsBlockedContent(newValue) {
                self.text.wrappedValue = oldValue
            }
        }
    }
}

