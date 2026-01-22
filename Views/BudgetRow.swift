//
//  BudgetRow.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct BudgetRow: View {
    let icon: String
    let label: String
    @Binding var amount: String
    let currency: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(currency)
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("", text: $amount)
                    .foregroundColor(.primary)
                    .font(.system(size: 17))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}


