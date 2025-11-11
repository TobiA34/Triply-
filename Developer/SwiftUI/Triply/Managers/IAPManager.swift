//
//  IAPManager.swift
//  Triply
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
    
    @Published private(set) var isPro: Bool = UserDefaults.standard.bool(forKey: "iap_is_pro")
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
    
    private init() { }
    
    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = Set([configuredProId])
            let fetched = try await Product.products(for: ids)
            products = fetched.sorted(by: { $0.price < $1.price })
            if products.isEmpty {
                lastInfoMessage = "Product not found. Check product ID in App Store Connect or set Info.plist key IAPProductProId."
            } else {
                lastInfoMessage = nil
            }
        } catch {
            lastErrorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    func purchasePro() async -> Bool {
        do {
            if products.isEmpty {
                await loadProducts()
            }
            guard let pro = products.first(where: { $0.id == configuredProId }) else {
                #if DEBUG
                // Fallback: unlock locally in DEBUG to avoid blocking QA/dev
                setProEntitlement(true)
                lastInfoMessage = "Debug: Pro unlocked (product not found). Configure App Store / StoreKit for real purchase."
                return true
                #else
                lastErrorMessage = "Pro product not found. Verify product ID and StoreKit configuration."
                return false
                #endif
            }
            let result = try await pro.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    setProEntitlement(true)
                    return true
                case .unverified(_, _):
                    lastErrorMessage = "Transaction could not be verified"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                lastErrorMessage = "Purchase is pending"
                return false
            @unknown default:
                return false
            }
        } catch {
            lastErrorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == configuredProId {
                setProEntitlement(true)
                return
            }
        }
        // No entitlement found
        setProEntitlement(false)
    }
    
    func observeTransactions() {
        let proId = configuredProId
        Task.detached { [weak self] in
            guard let self = self else { return }
            for await update in Transaction.updates {
                if case .verified(let transaction) = update,
                   transaction.productID == proId {
                    await transaction.finish()
                    await MainActor.run {
                        self.setProEntitlement(true)
                    }
                }
            }
        }
    }
    
    func refreshEntitlements() async {
        await restorePurchases()
    }
    
    private func setProEntitlement(_ enabled: Bool) {
        isPro = enabled
        UserDefaults.standard.set(enabled, forKey: "iap_is_pro")
        ThemeManager.shared.setUserTier(enabled ? .pro : .free)
    }
    
    #if DEBUG
    func debugUnlockPro() {
        setProEntitlement(true)
        lastInfoMessage = "Debug: Pro unlocked locally (no real purchase)."
    }
    #endif
}


