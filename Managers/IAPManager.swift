//
//  IAPManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    // Configure your in-app purchase product identifiers here
    // Replace with your real product id set in App Store Connect
    enum ProductID: String, CaseIterable {
        case pro = "com.triply.app.pro"
    }
    
    // In-app purchases are disabled. Treat all users as Pro.
    @Published private(set) var isPro: Bool = true
    @Published private(set) var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?
    @Published var lastInfoMessage: String?
    
    // Allow product id override via Info.plist key "IAPProductProId"
    private var configuredProId: String {
        if let id = Bundle.main.object(forInfoDictionaryKey: "IAPProductProId") as? String, !id.isEmpty {
            return id
        }
        return ProductID.pro.rawValue
    }
    
    private init() {
        // Ensure Pro is always enabled
        setProEntitlement(true)
    }
    
    // MARK: - Disabled IAP API
    //
    // All methods below are now no-ops so the app behaves as fully unlocked
    // without performing any StoreKit operations.
    
    func loadProducts() async {
        // No-op: in-app purchases disabled
        products = []
        lastInfoMessage = nil
        lastErrorMessage = nil
    }
    
    func purchasePro() async -> Bool {
        // Immediately mark Pro as unlocked
        setProEntitlement(true)
        lastInfoMessage = "Pro is unlocked. In-app purchases are disabled in this build."
        lastErrorMessage = nil
        return true
    }
    
    func restorePurchases() async {
        // No-op: always Pro, nothing to restore
        setProEntitlement(true)
        lastInfoMessage = "Restore not needed. Pro is already unlocked."
        lastErrorMessage = nil
    }
    
    func observeTransactions() {
        // No-op: we no longer observe StoreKit transactions
    }
    
    func refreshEntitlements() async {
        // No-op: entitlements are always granted
        setProEntitlement(true)
    }
    
    private func setProEntitlement(_ enabled: Bool) {
        isPro = enabled
        UserDefaults.standard.set(enabled, forKey: "iap_is_pro")
        ThemeManager.shared.setUserTier(.pro)
    }
    
    #if DEBUG
    func debugUnlockPro() {
        setProEntitlement(true)
        lastInfoMessage = "Debug: Pro unlocked locally (no real purchase)."
    }
    #endif
}


