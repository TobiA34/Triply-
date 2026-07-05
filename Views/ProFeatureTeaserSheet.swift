//
//  ProFeatureTeaserSheet.swift
//  Itinero
//
//  Pro feature teaser: shows the feature with a small gray X to dismiss and "Go to Pro" CTA.
//

import SwiftUI

/// Sheet presented when a non‑Pro user taps a Pro feature. Shows the feature, a gray X to close, and "Go to Pro".
struct ProFeatureTeaserSheet: View {
    let feature: ProFeatureTeaserItem
    let onDismiss: () -> Void
    let onGoToPro: () -> Void

    @State private var showPaywall = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Content: feature preview (grayed / locked style)
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(feature.color.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: feature.icon)
                            .font(.system(size: 32))
                            .foregroundColor(feature.color.opacity(0.7))
                    }
                    .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text(feature.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        Text(feature.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Text("pro.thisIsProFeature".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.systemGray5)))
                        .padding(.top, 4)

                    Text("pro.powerStatement".localized)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(feature.color)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    Spacer(minLength: 24)

                    // Go to Pro
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("pro.upgrade".localized)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                    Button {
                        onDismiss()
                    } label: {
                        Text("pro.viewAllFeatures".localized)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }

            // Small grayed-out X button (top trailing)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color(.systemGray5)))
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
            }
            .onDisappear {
                onDismiss()
            }
        }
    }
}

#Preview {
    ProFeatureTeaserSheet(
        feature: .aiPlan(),
        onDismiss: {},
        onGoToPro: {}
    )
}
