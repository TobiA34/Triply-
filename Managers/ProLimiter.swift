//
//  ProLimiter.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import SwiftData

@MainActor
class ProLimiter: ObservableObject {
    static let shared = ProLimiter()
    
    // Use StoreKit-based IAPManager for Pro entitlement instead of RevenueCat
    private let iapManager = IAPManager.shared
    
    // Free tier limits (carefully tuned to encourage upgrading while keeping the app useful)
    //
    // - Enough to fully plan a single real trip
    // - But you quickly feel the benefit of Pro once you start planning more
    private let maxTripsFree = 2                 // Plan up to 2 trips for free
    private let maxDestinationsPerTripFree = 4   // Great for a weekend or simple multi‑stop trip
    private let maxExpensesPerTripFree = 10      // Basic budgeting, detailed tracking is Pro
    private let maxActivitiesPerDayFree = 6      // Simple daily plan; full schedules are Pro
    private let maxPackingItemsFree = 25         // Core packing list; Pro for long/complex trips
    private let maxDocumentsPerTripFree = 5      // Key documents only
    private let maxFoldersFree = 2               // A couple of collections; power users go Pro
    // Theme system removed - no longer needed
    
    var isPro: Bool {
        iapManager.isPro
    }
    
    private init() { }
    
    // MARK: - Trip Limits
    
    func canCreateTrip(currentTripCount: Int) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentTripCount >= maxTripsFree {
            return (false, "Free users can create up to \(maxTripsFree) trips. Upgrade to Pro for unlimited trips.")
        }
        
        return (true, nil)
    }
    
    func getMaxTrips() -> Int {
        return isPro ? Int.max : maxTripsFree
    }
    
    // MARK: - Destination Limits
    
    func canAddDestination(currentDestinationCount: Int, tripName: String) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentDestinationCount >= maxDestinationsPerTripFree {
            return (false, "Free users can add up to \(maxDestinationsPerTripFree) destinations per trip. Upgrade to Pro for unlimited destinations.")
        }
        
        return (true, nil)
    }
    
    func getMaxDestinationsPerTrip() -> Int {
        return isPro ? Int.max : maxDestinationsPerTripFree
    }
    
    // MARK: - Expense Limits
    
    func canAddExpense(currentExpenseCount: Int, tripName: String) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentExpenseCount >= maxExpensesPerTripFree {
            return (false, "Free users can add up to \(maxExpensesPerTripFree) expenses per trip. Upgrade to Pro for unlimited expenses.")
        }
        
        return (true, nil)
    }
    
    func getMaxExpensesPerTrip() -> Int {
        return isPro ? Int.max : maxExpensesPerTripFree
    }
    
    // MARK: - Itinerary Activity Limits
    
    func canAddActivity(currentActivityCount: Int, date: Date) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentActivityCount >= maxActivitiesPerDayFree {
            return (false, "Free users can add up to \(maxActivitiesPerDayFree) activities per day. Upgrade to Pro for unlimited activities.")
        }
        
        return (true, nil)
    }
    
    func getMaxActivitiesPerDay() -> Int {
        return isPro ? Int.max : maxActivitiesPerDayFree
    }
    
    // MARK: - Packing List Limits
    
    func canAddPackingItem(currentItemCount: Int) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentItemCount >= maxPackingItemsFree {
            return (false, "Free users can add up to \(maxPackingItemsFree) packing items. Upgrade to Pro for unlimited items.")
        }
        
        return (true, nil)
    }
    
    func getMaxPackingItems() -> Int {
        return isPro ? Int.max : maxPackingItemsFree
    }
    
    // MARK: - Document Limits
    
    func canAddDocument(currentDocumentCount: Int, tripName: String) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentDocumentCount >= maxDocumentsPerTripFree {
            return (false, "Free users can add up to \(maxDocumentsPerTripFree) documents per trip. Upgrade to Pro for unlimited documents.")
        }
        
        return (true, nil)
    }
    
    func getMaxDocumentsPerTrip() -> Int {
        return isPro ? Int.max : maxDocumentsPerTripFree
    }
    
    // MARK: - Folder Limits
    
    func canCreateFolder(currentFolderCount: Int) -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        
        if currentFolderCount >= maxFoldersFree {
            return (false, "Free users can create up to \(maxFoldersFree) folders. Upgrade to Pro for unlimited folders.")
        }
        
        return (true, nil)
    }
    
    func getMaxFolders() -> Int {
        return isPro ? Int.max : maxFoldersFree
    }
    
    // MARK: - Premium Feature Access (Roamy-style)
    
    /// AI-Powered Smart Itinerary Generation
    func canAccessAIItineraryGeneration() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "AI-powered itinerary generation is a Pro feature. Upgrade to automatically create day-by-day plans from your destinations.")
    }
    
    /// Social Media Import (Instagram, Pinterest)
    func canAccessSocialMediaImport() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Import saved posts from Instagram and Pinterest is a Pro feature. Upgrade to turn your saved posts into trip destinations.")
    }
    
    /// Advanced Route Optimization
    func canAccessAdvancedRouteOptimization() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Advanced route optimization is a Pro feature. Upgrade to automatically optimize your itinerary for the shortest travel time.")
    }
    
    /// Offline Access
    func canAccessOfflineMode() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Offline access is a Pro feature. Upgrade to download trips and access them without internet.")
    }
    
    /// Advanced Export (PDF, Calendar, Share)
    func canAccessAdvancedExport() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Advanced export features (PDF, Calendar, Share) are Pro features. Upgrade to export your trips in multiple formats.")
    }
    
    /// Smart Packing Suggestions
    func canAccessSmartPackingSuggestions() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Smart packing suggestions based on weather and destination are Pro features. Upgrade for AI-powered packing recommendations.")
    }
    
    /// Weather-Based Recommendations
    func canAccessWeatherRecommendations() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Weather-based activity recommendations are Pro features. Upgrade to get suggestions based on forecast.")
    }
    
    /// Collaboration Features
    func canAccessCollaboration() -> (allowed: Bool, reason: String?) {
        if isPro {
            return (true, nil)
        }
        return (false, "Trip collaboration is a Pro feature. Upgrade to share trips and plan together with friends.")
    }
}




