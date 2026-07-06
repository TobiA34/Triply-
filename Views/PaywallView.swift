//
//  PaywallView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Presents the paywall configured in the RevenueCat dashboard for the
/// current offering, with the legal links Apple requires for subscriptions.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var iap = IAPManager.shared

    var body: some View {
        RevenueCatUI.PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                iap.apply(customerInfo: customerInfo)
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                iap.apply(customerInfo: customerInfo)
                if iap.isPro {
                    dismiss()
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 16) {
                    Link("Terms of Use", destination: IAPManager.termsOfUseURL)
                    Text("·").foregroundColor(.secondary)
                    Link("Privacy Policy", destination: IAPManager.privacyPolicyURL)
                }
                .font(.footnote)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
    }
}

#Preview {
    PaywallView()
}
