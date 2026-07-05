//
//  PaywallView.swift
//  Itinero
//
//  Shows the RevenueCat hosted paywall configured in the dashboard.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var iap = IAPManager.shared
    @State private var isPurchasing = false
    @State private var showingError = false

    private var privacyURL: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "AppPrivacyPolicyURL") as? String) ?? "https://example.com/privacy")!
    }

    private var termsURL: URL {
        URL(string: (Bundle.main.object(forInfoDictionaryKey: "AppTermsOfUseURL") as? String) ?? "https://example.com/terms")!
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Unlock Triply Pro")
                    .font(.title2.bold())
                Text("AI planning, advanced exports, templates, and premium productivity tools.")
                    .foregroundColor(.secondary)

                if iap.isLoading {
                    ProgressView("Loading plans...")
                        .padding(.vertical, 12)
                } else if iap.availablePackages.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Plans are temporarily unavailable.")
                            .font(.headline)
                        Text("Please try again in a moment.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await iap.loadProducts() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(iap.availablePackages) { package in
                        Button {
                            Task {
                                isPurchasing = true
                                let ok = await iap.purchasePackage(identifier: package.id)
                                isPurchasing = false
                                if ok {
                                    dismiss()
                                } else if !(iap.lastErrorMessage ?? "").isEmpty {
                                    showingError = true
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(package.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    if let intro = package.introPrice, package.introEligible {
                                        Text("Intro: \(intro)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(package.price)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Restore Purchases") {
                    Task {
                        await iap.restorePurchases()
                        if !(iap.lastErrorMessage ?? "").isEmpty {
                            showingError = true
                        }
                    }
                }
                .padding(.top, 6)

                if let info = iap.lastInfoMessage, !info.isEmpty {
                    Text(info)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Link("Privacy Policy", destination: privacyURL)
                    Text("•")
                    Link("Terms of Use", destination: termsURL)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Triply Pro")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await iap.loadProducts()
        }
        .overlay {
            if isPurchasing {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text((iap.lastErrorMessage?.isEmpty == false ? iap.lastErrorMessage! : "Something went wrong. Please try again."))
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
    }
}

