//
//  CurrencySelectionView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct CurrencySelectionView: View {
    @Binding var selectedCurrency: Currency
    @Environment(\.dismiss) var dismiss
    @State private var enhancedCurrency: EnhancedCurrency
    
    init(selectedCurrency: Binding<Currency>) {
        self._selectedCurrency = selectedCurrency
        // Convert to EnhancedCurrency for the picker
        self._enhancedCurrency = State(initialValue: selectedCurrency.wrappedValue.enhanced)
    }
    
    var body: some View {
        CurrencyPickerView(selectedCurrency: $enhancedCurrency)
            .onChange(of: enhancedCurrency) { oldValue, newValue in
                // Convert back to legacy Currency when selection changes
                selectedCurrency = newValue.legacy
                print("✅ Selected currency: \(newValue.code) (\(newValue.name))")
            }
            .onDisappear {
                // Ensure binding is updated when view disappears
                selectedCurrency = enhancedCurrency.legacy
            }
    }
}

#Preview {
    NavigationStack {
        CurrencySelectionView(selectedCurrency: .constant(Currency.currency(for: "USD")))
    }
}

