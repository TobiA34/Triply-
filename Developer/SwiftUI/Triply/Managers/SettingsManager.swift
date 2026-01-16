//
//  SettingsManager.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var currentCurrency: Currency = Currency.currency(for: "USD")
    
    private init() {
        // Load from UserDefaults as fallback
        if let savedCode = UserDefaults.standard.string(forKey: "savedCurrencyCode") {
            currentCurrency = Currency.currency(for: savedCode)
        }
    }
    
    // CREATE - Create default settings if none exist (async, non-blocking)
    func createDefaultSettings(in context: ModelContext) {
        // Use Task with low priority to avoid blocking UI
        Task(priority: .utility) {
            let singletonID = AppSettings.singletonID
            let descriptor = FetchDescriptor<AppSettings>(
                predicate: #Predicate<AppSettings> { settings in
                    settings.id == singletonID
                }
            )
            
            do {
                let existing = try context.fetch(descriptor).first
                if existing == nil {
                    let defaultSettings = AppSettings(
                        id: AppSettings.singletonID,
                        currencyCode: "USD",
                        currencySymbol: "$"
                    )
                    context.insert(defaultSettings)
                    try context.save()
                    print("✅ Created default settings")
                }
            } catch {
                print("❌ Failed to create default settings: \(error)")
            }
        }
    }
    
    // READ - Load settings from database (async, non-blocking)
    func loadSettings(from context: ModelContext) {
        // Use Task to avoid blocking navigation - settings load in background
        Task(priority: .userInitiated) { [weak self] in
            // First, try fast UserDefaults fallback (synchronous, instant)
            if let savedCode = UserDefaults.standard.string(forKey: "savedCurrencyCode") {
                await MainActor.run {
                    guard let self = self else { return }
                    self.currentCurrency = Currency.currency(for: savedCode)
                }
            }
            
            // Then load from database (async, non-blocking)
            let singletonID = AppSettings.singletonID
            let descriptor = FetchDescriptor<AppSettings>(
                predicate: #Predicate<AppSettings> { settings in
                    settings.id == singletonID
                }
            )
            
            do {
                let settings = try context.fetch(descriptor).first
                await MainActor.run {
                    guard let self = self else { return }
                    if let settings = settings {
                        self.currentCurrency = Currency.currency(for: settings.currencyCode)
                        // Also save to UserDefaults as backup
                        UserDefaults.standard.set(settings.currencyCode, forKey: "savedCurrencyCode")
                    } else {
                        // No settings found, create default (async)
                        self.createDefaultSettings(in: context)
                        // Keep current currency (already set from UserDefaults above)
                    }
                }
            } catch {
                // Error loading from DB - keep UserDefaults value (already set above)
                print("❌ Failed to load settings: \(error)")
            }
        }
    }
    
    // UPDATE - Update currency in database
    func updateCurrency(_ currency: Currency, in context: ModelContext) {
        // Use singleton ID to fetch
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate<AppSettings> { settings in
                settings.id == singletonID
            }
        )
        
        do {
            if let settings = try context.fetch(descriptor).first {
                // UPDATE existing
                settings.currencyCode = currency.code
                settings.currencySymbol = currency.symbol
                try context.save()
                print("✅ Updated currency in DB to: \(currency.code)")
            } else {
                // CREATE new if doesn't exist (shouldn't happen, but handle it)
                print("⚠️ Settings not found, creating new...")
                let newSettings = AppSettings(
                    id: AppSettings.singletonID,
                    currencyCode: currency.code,
                    currencySymbol: currency.symbol
                )
                context.insert(newSettings)
                try context.save()
                print("✅ Created new currency settings: \(currency.code)")
            }
            
            // Update published property
            currentCurrency = currency
            
            // Save to UserDefaults as backup
            UserDefaults.standard.set(currency.code, forKey: "savedCurrencyCode")
            
            // Notify observers
            objectWillChange.send()
        } catch {
            print("❌ Failed to update currency: \(error)")
            // Still update in memory and UserDefaults
            currentCurrency = currency
            UserDefaults.standard.set(currency.code, forKey: "savedCurrencyCode")
            objectWillChange.send()
        }
    }
    
    // DELETE - Not needed for settings, but included for completeness
    func deleteSettings(in context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(descriptor).first {
            context.delete(settings)
            try? context.save()
            currentCurrency = Currency.currency(for: "USD")
            objectWillChange.send()
        }
    }
    
    func formatAmount(_ amount: Double) -> String {
        return "\(currentCurrency.symbol)\(String(format: "%.2f", amount))"
    }
}

