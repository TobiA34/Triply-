//
//  ReviewRequestManager.swift
//  Itinero
//
//  Created on 2026
//

import Foundation

/// Decides when to ask for an App Store review. The system caps prompts at
/// 3 per 365 days, but we only ask once the user has saved enough trips to
/// have experienced real value.
enum ReviewRequestManager {
    private static let savedTripCountKey = "review_saved_trip_count"
    private static let lastPromptedCountKey = "review_last_prompted_count"

    /// Trips the user must save before the first review ask.
    private static let firstAskThreshold = 3
    /// Additional trips between subsequent asks.
    private static let repeatAskInterval = 10

    /// Call after a trip is saved. Returns true when the app should request
    /// a review right now.
    static func shouldRequestReviewAfterTripSaved() -> Bool {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: savedTripCountKey) + 1
        defaults.set(count, forKey: savedTripCountKey)

        let lastPrompted = defaults.integer(forKey: lastPromptedCountKey)
        let dueForFirstAsk = lastPrompted == 0 && count >= firstAskThreshold
        let dueForRepeatAsk = lastPrompted > 0 && count - lastPrompted >= repeatAskInterval

        guard dueForFirstAsk || dueForRepeatAsk else { return false }
        defaults.set(count, forKey: lastPromptedCountKey)
        return true
    }
}
