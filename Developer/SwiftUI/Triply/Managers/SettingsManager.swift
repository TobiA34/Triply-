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
    
    // CREATE - Create default settings if none exist
    func createDefaultSettings(in context: ModelContext) {
        // Use singleton ID to fetch or create
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate<AppSettings> { settings in
                settings.id == singletonID
            }
        )
        
        do {
            if try context.fetch(descriptor).first == nil {
                let defaultSettings = AppSettings(
                    id: AppSettings.singletonID,
                    currencyCode: "USD",
                    currencySymbol: "$"
                )
                context.insert(defaultSettings)
                try context.save()
                print("✅ Created default settings")
            } else {
                print("✅ Settings already exist")
            }
        } catch {
            print("❌ Failed to create default settings: \(error)")
        }
    }
    
    // READ - Load settings from database
    func loadSettings(from context: ModelContext) {
        // Use singleton ID to fetch
        let singletonID = AppSettings.singletonID
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate<AppSettings> { settings in
                settings.id == singletonID
            }
        )
        
        do {
            let settings = try context.fetch(descriptor).first
            if let settings = settings {
                currentCurrency = Currency.currency(for: settings.currencyCode)
                // Also save to UserDefaults as backup
                UserDefaults.standard.set(settings.currencyCode, forKey: "savedCurrencyCode")
                print("✅ Loaded currency from DB: \(settings.currencyCode)")
            } else {
                // No settings found, create default
                print("⚠️ No settings found, creating default...")
                createDefaultSettings(in: context)
                // Reload after creation
                if let newSettings = try? context.fetch(descriptor).first {
                    currentCurrency = Currency.currency(for: newSettings.currencyCode)
                } else {
                    currentCurrency = Currency.currency(for: "USD")
                }
            }
        } catch {
            print("❌ Failed to load settings: \(error)")
            // Fallback to UserDefaults
            if let savedCode = UserDefaults.standard.string(forKey: "savedCurrencyCode") {
                currentCurrency = Currency.currency(for: savedCode)
                print("✅ Loaded currency from UserDefaults: \(savedCode)")
            } else {
                currentCurrency = Currency.currency(for: "USD")
            }
        }
        objectWillChange.send()
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

