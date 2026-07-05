//
//  ProUpsellBanner.swift
//  Itinero
//
//  Created on 2026
//

import SwiftUI
import RevenueCat

/// Compact home-screen banner promoting Itinero Pro. Tapping it presents
/// the paywall via the provided action.
struct ProUpsellBanner: View {
    let action: () -> Void
    @ObservedObject private var iapManager = IAPManager.shared

    private var priceLine: String {
        if let package = iapManager.currentOffering?.availablePackages.first {
            return "from \(package.localizedPriceString)"
        }
        return "Try it today"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Itinero Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("Unlimited trips, activities & more · \(priceLine)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(bannerBackground)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home_pro_banner")
        .accessibilityLabel("Unlock Itinero Pro. Unlimited trips, activities, and more. \(priceLine)")
    }

    @ViewBuilder
    private var bannerBackground: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)
                .glassEffect(.regular, in: .rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ProUpsellBanner {}
        .padding()
}
