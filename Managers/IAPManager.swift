//
//  IAPManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import RevenueCat

@MainActor
final class IAPManager: NSObject, ObservableObject {
    static let shared = IAPManager()

    /// RevenueCat public SDK key for the production App Store app.
    private static let revenueCatAPIKey = "appl_hCVOroIcXfOaoshwTdYHYnnpzvU"

    /// Entitlement identifier configured in the RevenueCat dashboard.
    static let proEntitlementID = "Itinero Pro"

    static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicyURL = URL(string: "https://gist.github.com/tunds/fb42e2abd3bbd61336d1bee99dbcafec")!

    @Published private(set) var isPro: Bool = false
    @Published private(set) var currentOffering: Offering?
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?
    @Published var lastInfoMessage: String?

    /// Call once at app launch, before any other IAPManager use.
    static func configure() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .error
        #endif
        Purchases.configure(withAPIKey: revenueCatAPIKey)
        Purchases.shared.delegate = shared
        Task {
            await shared.refreshEntitlements()
            await shared.loadProducts(quiet: true)
        }
    }

    private override init() {
        super.init()
    }

    /// Loads offerings. Errors are only surfaced to the UI when `quiet` is
    /// false (user-initiated flows); the background prefetch at launch stays
    /// silent so the app never looks broken on start.
    func loadProducts(quiet: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            lastErrorMessage = nil
        } catch {
            print("Failed to load offerings: \(error)")
            if !quiet {
                lastErrorMessage = "Subscriptions aren't available right now. Please check your connection and try again."
            }
        }
    }

    /// Loads offerings if needed. Returns true when the paywall has packages
    /// to sell — callers must not present the paywall otherwise, so users
    /// never see a configuration error alert.
    func preparePaywall() async -> Bool {
        if currentOffering?.availablePackages.isEmpty == false {
            return true
        }
        await loadProducts()
        return currentOffering?.availablePackages.isEmpty == false
    }

    /// Purchases the first available package of the current offering.
    /// The paywall UI normally drives purchases; this is a programmatic fallback.
    func purchasePro() async -> Bool {
        if currentOffering == nil {
            await loadProducts()
        }
        guard let package = currentOffering?.availablePackages.first else {
            lastErrorMessage = "Subscription options are unavailable right now."
            return false
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(customerInfo: result.customerInfo)
            return isPro
        } catch let error as RevenueCat.ErrorCode where error == .purchaseCancelledError {
            return false
        } catch {
            lastErrorMessage = "Purchase failed. Please try again."
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo: customerInfo)
            lastInfoMessage = isPro
                ? "Your Itinero Pro subscription has been restored."
                : "No previous purchases were found for this Apple Account."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Restore failed. Please try again."
        }
    }

    func observeTransactions() {
        // RevenueCat observes transactions itself; updates arrive via the delegate.
    }

    func refreshEntitlements() async {
        if let customerInfo = try? await Purchases.shared.customerInfo() {
            apply(customerInfo: customerInfo)
        }
    }

    func apply(customerInfo: CustomerInfo) {
        let active = customerInfo.entitlements[Self.proEntitlementID]?.isActive == true
        isPro = active
        UserDefaults.standard.set(active, forKey: "iap_is_pro")
        ThemeManager.shared.setUserTier(active ? .pro : .free)
    }

    #if DEBUG
    func debugUnlockPro() {
        isPro = true
        UserDefaults.standard.set(true, forKey: "iap_is_pro")
        ThemeManager.shared.setUserTier(.pro)
        lastInfoMessage = "Debug: Pro unlocked locally (no real purchase)."
    }
    #endif
}

extension IAPManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.apply(customerInfo: customerInfo)
        }
    }
}
