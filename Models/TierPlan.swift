//
//  TierPlan.swift
//  Itinero
//
//  Single source of truth for Free vs Pro tiers and feature copy.
//

import Foundation
import SwiftUI

// MARK: - Tiers

enum AppTier: String, CaseIterable {
    case free
    case pro
}

// MARK: - Limits (must match ProLimiter)

struct TierLimits {
    static let freeTrips = 2
    static let freeDestinationsPerTrip = 4
    static let freeExpensesPerTrip = 10
    static let freeActivitiesPerDay = 6
    static let freePackingItems = 25
    static let freeDocumentsPerTrip = 5
    static let freeFolders = 2

    static func limitDescription(_ name: String, free: Int, pro: String = "Unlimited") -> (name: String, free: String, pro: String) {
        (name, "\(free)", pro)
    }
}

// MARK: - Feature definition

struct TierFeature: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let color: Color
    let tier: AppTier
}

// MARK: - Tier plan (all Pro features with concrete descriptions)

enum TierPlan {
    /// Limits table: (title, free value, pro value)
    static var limitsTable: [(title: String, icon: String, free: String, pro: String)] {
        [
            ("Trips", "airplane", "\(TierLimits.freeTrips)", "Unlimited"),
            ("Destinations per trip", "mappin.circle", "\(TierLimits.freeDestinationsPerTrip)", "Unlimited"),
            ("Activities per day", "list.bullet.clipboard", "\(TierLimits.freeActivitiesPerDay)", "Unlimited"),
            ("Expenses per trip", "creditcard", "\(TierLimits.freeExpensesPerTrip)", "Unlimited"),
            ("Packing list items", "suitcase", "\(TierLimits.freePackingItems)", "Unlimited"),
            ("Documents per trip", "doc.text", "\(TierLimits.freeDocumentsPerTrip)", "Unlimited"),
            ("Folders", "folder", "\(TierLimits.freeFolders)", "Unlimited"),
        ]
    }

    /// Pro-only features for the “Premium tools” section (concrete, not vague).
    static var proFeatures: [TierFeature] {
        [
            TierFeature(
                id: "ai_plan",
                title: "tierPlan.ai.plan.generator".localized,
                detail: "Generate a full day-by-day itinerary from your destinations. One tap to get suggested activities, timing, and order.",
                icon: "sparkles.rectangle.stack",
                color: .purple,
                tier: .pro
            ),
            TierFeature(
                id: "optimizer",
                title: "optimizer.title".localized,
                detail: "Reorder activities by time and location to reduce travel between stops and fix scheduling conflicts.",
                icon: "arrow.triangle.2.circlepath",
                color: .blue,
                tier: .pro
            ),
            TierFeature(
                id: "budget_insights",
                title: "budget.insightsTitle".localized,
                detail: "See spending by category, track budget vs actual, and get suggestions to stay on track.",
                icon: "chart.pie.fill",
                color: .teal,
                tier: .pro
            ),
            TierFeature(
                id: "smart_packing",
                title: "tripDetail.smartPacking".localized,
                detail: "AI packing list based on destination, trip length, and weather so you don’t forget essentials.",
                icon: "suitcase.fill",
                color: .mint,
                tier: .pro
            ),
            TierFeature(
                id: "collaboration",
                title: "tierPlan.trip.collaboration".localized,
                detail: "Invite friends or family to edit the trip, add activities, and split expenses together.",
                icon: "person.2.fill",
                color: .indigo,
                tier: .pro
            ),
            TierFeature(
                id: "social_import",
                title: "tierPlan.import.from.instagram.tiktok".localized,
                detail: "Turn saved posts into trip destinations with one tap. Build your trip from places you’ve already saved.",
                icon: "square.and.arrow.down.on.square",
                color: .pink,
                tier: .pro
            ),
            TierFeature(
                id: "advanced_export",
                title: "tierPlan.advanced.export".localized,
                detail: "Export itinerary as PDF, add events to Apple Calendar, and share a rich link with others.",
                icon: "square.and.arrow.up",
                color: .orange,
                tier: .pro
            ),
            TierFeature(
                id: "pro_templates",
                title: "tierPlan.pro.trip.templates".localized,
                detail: "Start from curated templates (city breaks, road trips) with destinations and structure already set.",
                icon: "square.grid.2x2.fill",
                color: .cyan,
                tier: .pro
            ),
            TierFeature(
                id: "expense_splitting",
                title: "tierPlan.expense.splitting".localized,
                detail: "Split costs with trip mates and see who owes what. Supports equal or custom splits.",
                icon: "dollarsign.circle.fill",
                color: .green,
                tier: .pro
            ),
            TierFeature(
                id: "folder_customization",
                title: "tierPlan.folder.icon.customization".localized,
                detail: "More folder icons and full color picker for organizing documents your way.",
                icon: "folder.fill.badge.gearshape",
                color: .gray,
                tier: .pro
            ),
        ]
    }

    /// Short list for paywall (title only or title + one line).
    static var paywallFeatureTitles: [(icon: String, title: String)] {
        [
            ("sparkles.rectangle.stack", "AI Plan Generator"),
            ("arrow.triangle.2.circlepath", "Trip Optimizer"),
            ("chart.pie.fill", "Budget Insights"),
            ("suitcase.fill", "Smart Packing"),
            ("person.2.fill", "Trip Collaboration"),
            ("square.and.arrow.down.on.square", "Import from Instagram & TikTok"),
            ("square.and.arrow.up", "PDF & Calendar Export"),
            ("square.grid.2x2.fill", "Pro Trip Templates"),
            ("dollarsign.circle.fill", "Expense Splitting"),
            ("folder.fill.badge.gearshape", "Unlimited folders & customization"),
        ]
    }

    /// Free tier summary (what you get without paying).
    static let freeTierSummary = """
    • Up to \(TierLimits.freeTrips) trips
    • \(TierLimits.freeDestinationsPerTrip) destinations per trip
    • \(TierLimits.freeActivitiesPerDay) activities per day
    • \(TierLimits.freeExpensesPerTrip) expenses per trip
    • \(TierLimits.freePackingItems) packing items
    • \(TierLimits.freeDocumentsPerTrip) documents per trip
    • \(TierLimits.freeFolders) folders
    • Manual itinerary, expenses, and packing
    • Basic share and text export
    • Free trip templates
    """

    /// Pro tier headline for hero.
    static let proHeadline = "Unlock unlimited trips and every planning tool."
    static let proSubheadline = "AI plans, optimization, budget insights, smart packing, collaboration, and more—all in one place."
}
