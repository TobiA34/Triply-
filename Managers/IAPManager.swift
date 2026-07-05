//
//  IAPManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import StoreKit

#if canImport(RevenueCat)
import RevenueCat
#endif

/// RevenueCat entitlement identifier for Pro access. Must match the identifier in RevenueCat dashboard.
private let revenueCatProEntitlementId = "pro"

/// Display model for a RevenueCat package (avoids exposing RevenueCat types to views).
struct ProPackageDisplay: Identifiable {
    let id: String
    let title: String
    let price: String
    let introPrice: String?
    let introEligible: Bool
}

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()

    enum ProductID: String, CaseIterable {
        case pro = "com.triply.app.pro"
    }

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var lastErrorMessage: String?
    @Published var lastInfoMessage: String?

    /// Primary price string for backward compatibility (first package or single package).
    @Published private(set) var proPriceString: String?

    /// All RevenueCat packages from current offering (e.g. monthly, annual, lifetime) for paywall.
    @Published private(set) var availablePackages: [ProPackageDisplay] = []

    private var configuredProId: String {
        if let id = Bundle.main.object(forInfoDictionaryKey: "IAPProductProId") as? String, !id.isEmpty {
            return id
        }
        return ProductID.pro.rawValue
    }

    #if canImport(RevenueCat)
    private var packageByIdentifier: [String: Package] = [:]
    private let revenueCatAPIKey = (Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String) ?? ""
    #endif

    private init() {
        #if canImport(RevenueCat)
        configureRevenueCatIfNeeded()
        #endif
        // Do not unlock Pro when RevenueCat is not configured (e.g. first launch before .onAppear).
        // Pro state is set only after fetching customerInfo or after a successful purchase/restore.
        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured {
            Task { await refreshEntitlementsFromRevenueCat() }
        }
        #endif
    }

    #if canImport(RevenueCat)
    private func configureRevenueCatIfNeeded() {
        if RevenueCat.Purchases.isConfigured { return }
        let key = revenueCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard key.hasPrefix("appl_") || key.hasPrefix("rcapp_") else {
            lastInfoMessage = "Purchases are temporarily unavailable."
            return
        }
        RevenueCat.Purchases.logLevel = .warn
        RevenueCat.Purchases.configure(withAPIKey: key)
    }
    #endif

    func loadProducts() async {
        isLoading = true
        lastErrorMessage = nil
        lastInfoMessage = nil

        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured {
            do {
                let offerings = try await RevenueCat.Purchases.shared.offerings()
                // Prefer "current", but fall back to first available offering to avoid
                // empty paywall UI when dashboard "current offering" isn't selected yet.
                let offering = offerings.current ?? offerings.all.values.first
                guard let offering else {
                    availablePackages = []
                    proPriceString = nil
                    isLoading = false
                    return
                }
                let packages = orderedPackages(from: offering)
                let productIds = packages.map { $0.storeProduct.productIdentifier }
                let eligibility = await RevenueCat.Purchases.shared.checkTrialOrIntroDiscountEligibility(productIdentifiers: productIds)
                var display: [ProPackageDisplay] = []
                var byId: [String: Package] = [:]
                for pkg in packages {
                    byId[pkg.identifier] = pkg
                    let status = eligibility[pkg.storeProduct.productIdentifier]?.status ?? .unknown
                    let introEligible = (status == .eligible)
                    let introPrice: String? = pkg.localizedIntroductoryPriceString
                    display.append(ProPackageDisplay(
                        id: pkg.identifier,
                        title: packageTitle(pkg),
                        price: pkg.localizedPriceString,
                        introPrice: introPrice,
                        introEligible: introEligible
                    ))
                }
                availablePackages = display
                packageByIdentifier = byId
                proPriceString = display.first?.price
                await refreshEntitlementsFromRevenueCat()
            } catch {
                lastErrorMessage = Self.sanitizedErrorMessage(error.localizedDescription)
                availablePackages = []
            }
            isLoading = false
            return
        }
        #endif

        products = []
        lastInfoMessage = nil
        isLoading = false
    }

    #if canImport(RevenueCat)
    private func orderedPackages(from offering: Offering) -> [Package] {
        var list: [Package] = []
        if let p = offering.lifetime { list.append(p) }
        if let p = offering.annual { list.append(p) }
        if let p = offering.sixMonth { list.append(p) }
        if let p = offering.threeMonth { list.append(p) }
        if let p = offering.twoMonth { list.append(p) }
        if let p = offering.monthly { list.append(p) }
        if let p = offering.weekly { list.append(p) }
        let added = Set(list.map(\.identifier))
        for p in offering.availablePackages where !added.contains(p.identifier) {
            list.append(p)
        }
        return list
    }

    private func packageTitle(_ pkg: Package) -> String {
        switch pkg.packageType {
        case .lifetime: return "Lifetime"
        case .annual: return "Annual"
        case .sixMonth: return "6 Months"
        case .threeMonth: return "3 Months"
        case .twoMonth: return "2 Months"
        case .monthly: return "Monthly"
        case .weekly: return "Weekly"
        default: return pkg.identifier
        }
    }
    #endif

    /// Purchase Pro by selecting a package (RevenueCat). Use the package's `id` from `availablePackages`.
    func purchasePackage(identifier: String) async -> Bool {
        #if canImport(RevenueCat)
        guard RevenueCat.Purchases.isConfigured, let package = packageByIdentifier[identifier] else {
            lastErrorMessage = "Package not available."
            return false
        }
        do {
            let result = try await RevenueCat.Purchases.shared.purchase(package: package)
            applyCustomerInfo(result.customerInfo)
            if result.customerInfo.entitlements[revenueCatProEntitlementId]?.isActive == true {
                lastInfoMessage = "Pro unlocked."
                lastErrorMessage = nil
                return true
            }
            lastErrorMessage = "Purchase completed but entitlement not active yet."
            return false
        } catch {
            let ns = error as NSError
            if ns.domain == RevenueCat.ErrorCode.errorDomain && ns.code == RevenueCat.ErrorCode.purchaseCancelledError.rawValue {
                lastInfoMessage = nil
                lastErrorMessage = nil
                return false
            }
            lastErrorMessage = Self.sanitizedErrorMessage(error.localizedDescription)
            return false
        }
        #endif
        setProEntitlement(true)
        return true
    }

    func purchasePro() async -> Bool {
        if let first = availablePackages.first {
            return await purchasePackage(identifier: first.id)
        }
        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured, let package = packageByIdentifier.values.first {
            return await purchasePackage(identifier: package.identifier)
        }
        #endif
        lastInfoMessage = "Pro is unlocked. In-app purchases are disabled in this build."
        lastErrorMessage = nil
        setProEntitlement(true)
        return true
    }

    func restorePurchases() async {
        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured {
            do {
                let customerInfo = try await RevenueCat.Purchases.shared.restorePurchases()
                applyCustomerInfo(customerInfo)
                if isPro {
                    lastInfoMessage = "Purchases restored."
                } else {
                    lastInfoMessage = "No Pro purchase found to restore."
                }
                lastErrorMessage = nil
            } catch {
                lastErrorMessage = Self.sanitizedErrorMessage(error.localizedDescription)
                lastInfoMessage = nil
            }
            return
        }
        #endif
        setProEntitlement(true)
        lastInfoMessage = "Restore not needed. Pro is already unlocked."
        lastErrorMessage = nil
    }

    /// Presents the system manage subscriptions sheet (RevenueCat). Call when user is Pro.
    func showManageSubscriptions() async {
        #if canImport(RevenueCat)
        guard RevenueCat.Purchases.isConfigured else { return }
        do {
            try await RevenueCat.Purchases.shared.showManageSubscriptions()
        } catch {
            lastErrorMessage = Self.sanitizedErrorMessage(error.localizedDescription)
        }
        #endif
    }

    /// In release builds, avoid showing sandbox or technical errors to users.
    private static func sanitizedErrorMessage(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("credentials") || lower.contains("configuration") || lower.contains("error 11") || lower.contains("error 23") {
            return "Purchases are temporarily unavailable. Please try again later."
        }
        if lower.contains("sandbox") || lower.contains("unavailable") || lower.contains("could not connect") {
            return "Unable to load offers. Check your connection and try again."
        }
        if lower.contains("cancelled") || lower.contains("canceled") { return "" }
        return "Something went wrong. Please try again or restore purchases."
    }

    /// Set subscriber email for receipts and support (RevenueCat).
    func setUserEmail(_ email: String?) {
        #if canImport(RevenueCat)
        guard RevenueCat.Purchases.isConfigured else { return }
        RevenueCat.Purchases.shared.attribution.setEmail(email)
        #endif
    }

    func observeTransactions() {
        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured {
            Task { await refreshEntitlementsFromRevenueCat() }
        }
        #endif
    }

    func refreshEntitlements() async {
        #if canImport(RevenueCat)
        if RevenueCat.Purchases.isConfigured {
            await refreshEntitlementsFromRevenueCat()
            return
        }
        #endif
        setProEntitlement(true)
    }

    #if canImport(RevenueCat)
    private func refreshEntitlementsFromRevenueCat() async {
        guard RevenueCat.Purchases.isConfigured else { return }
        do {
            let customerInfo = try await RevenueCat.Purchases.shared.customerInfo()
            applyCustomerInfo(customerInfo)
        } catch {
            // Keep previous isPro state on fetch error
        }
    }

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        let active = customerInfo.entitlements[revenueCatProEntitlementId]?.isActive == true
        setProEntitlement(active)
    }
    #endif

    private func setProEntitlement(_ enabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPro = enabled
            UserDefaults.standard.set(enabled, forKey: "iap_is_pro")
            ThemeManager.shared.setUserTier(enabled ? .pro : .free)
        }
    }

    #if DEBUG
    func debugUnlockPro() {
        setProEntitlement(true)
        lastInfoMessage = "Debug: Pro unlocked locally (no real purchase)."
    }
    #endif
}
