//
//  PaywallView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var iap = IAPManager.shared
    @State private var isPurchasing = false
    @State private var showFeatures = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.yellow)
                    .padding(.top, 24)
                
                Text("Itinero Pro")
                    .font(.largeTitle).bold()
                
                VStack(alignment: .leading, spacing: 12) {
                    featureRow("AI Chat Assistant", "message.fill")
                    featureRow("Smart Suggestions", "lightbulb.fill")
                    featureRow("Trip Analysis", "brain.head.profile")
                    featureRow("Receipt Scanner", "doc.text.viewfinder")
                    featureRow("Budget Insights", "chart.pie.fill")
                    featureRow("Itinerary Optimizer", "calendar.badge.clock")
                    featureRow("AI Plan Generator", "calendar.badge.plus")
                    featureRow("Unlimited custom themes", "paintpalette.fill")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                
                Button {
                    showFeatures = true
                } label: {
                    HStack {
                        Text("View All Pro Features")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                if let pro = iap.products.first(where: { $0.id == IAPManager.ProductID.pro.rawValue }) {
                    Text(pro.displayPrice)
                        .font(.title2).bold()
                } else {
                    VStack(spacing: 6) {
                        Text("Loading price...")
                            .foregroundColor(.secondary)
                        if let info = iap.lastInfoMessage {
                            Text(info).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    Button {
                        Task {
                            isPurchasing = true
                            let success = await iap.purchasePro()
                            isPurchasing = false
                            if success { dismiss() }
                        }
                    } label: {
                        HStack {
                            if isPurchasing { ProgressView().tint(.white) }
                            Text(isPurchasing ? "Purchasing..." : "Unlock Pro")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPurchasing)
                    
                    Button("Restore Purchases") {
                        Task { await iap.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                }
                
                if let msg = iap.lastErrorMessage {
                    Text(msg).foregroundColor(.red).font(.footnote)
                }
                
                #if DEBUG
                Divider().padding(.vertical, 8)
                Button {
                    iap.debugUnlockPro()
                    dismiss()
                } label: {
                    Text("Debug: Unlock Pro (no charge)").bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                #endif
                
                Text("One-time purchase. No subscription.\nManage purchases in App Store settings.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Upgrade to Pro")
        .sheet(isPresented: $showFeatures) {
            NavigationStack {
                ProFeaturesView()
            }
        }
        .task {
            await iap.loadProducts()
            iap.observeTransactions()
        }
    }
    
    private func featureRow(_ title: String, _ systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.accentColor)
            Text(title)
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}


