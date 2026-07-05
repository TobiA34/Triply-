//
//  TripTemplates.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

enum TripTemplate {
    case beach
    case mountain
    case city
    case business
    case romantic
}

struct TemplateCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 100, height: 88)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24, alignment: .center)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }
}

