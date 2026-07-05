//
//  ProHomePaywallBanner.swift
//  Itinero
//
//  Home (trips) screen banner for non‑Pro users; tap opens the paywall.
//

import SwiftUI

struct ProHomePaywallBanner: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let onUpgrade: () -> Void

    @AppStorage("home_pro_banner_dismissed") private var bannerDismissed = false

    var body: some View {
        if bannerDismissed {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.85), themeManager.currentPalette.accent.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("home.proBanner.title".localized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(themeManager.currentPalette.text)
                        Text("home.proBanner.subtitle".localized)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        bannerDismissed = true
                        HapticManager.shared.selection()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("common.close".localized)
                }

                Button {
                    HapticManager.shared.selection()
                    onUpgrade()
                } label: {
                    HStack {
                        Text("home.proBanner.cta".localized)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [.purple, themeManager.currentPalette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .fill(themeManager.currentPalette.background)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                            .stroke(themeManager.currentPalette.accent.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
            .accessibilityElement(children: .combine)
        }
    }
}
