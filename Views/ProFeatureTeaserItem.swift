//
//  ProFeatureTeaserItem.swift
//  Itinero
//
//  Data for a single Pro feature teaser (title, subtitle, icon, color).
//

import SwiftUI

/// Data for a single Pro feature teaser (title, subtitle, icon, color).
struct ProFeatureTeaserItem: Identifiable {
    var id: String { icon + title }
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

// MARK: - Helpers for TripDetailView

extension ProFeatureTeaserItem {
    static func aiPlan() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.aiPlan".localized,
            subtitle: "tripDetail.aiPlanSubtitle".localized,
            icon: "sparkles",
            color: .purple
        )
    }
    static func optimizer() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.optimize".localized,
            subtitle: "tripDetail.optimizeSubtitle".localized,
            icon: "wand.and.stars",
            color: .blue
        )
    }
    static func budgetAI() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.budgetAI".localized,
            subtitle: "tripDetail.budgetAISubtitle".localized,
            icon: "chart.pie.fill",
            color: .teal
        )
    }
    static func collaborate() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.collaborateShort".localized,
            subtitle: "tripDetail.collaborateSubtitle".localized,
            icon: "person.2.fill",
            color: .indigo
        )
    }
    static func smartPacking() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.smartPacking".localized,
            subtitle: "tripDetail.smartPackingSubtitle".localized,
            icon: "suitcase.fill",
            color: .orange
        )
    }
    static func exportFeature() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.exportShort".localized,
            subtitle: "tripDetail.exportSubtitle".localized,
            icon: "square.and.arrow.up",
            color: .green
        )
    }
    static func moreDestinations() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "destination.title".localized,
            subtitle: "pro.moreDestinationsSubtitle".localized,
            icon: "mappin.circle.fill",
            color: .blue
        )
    }
    static func socialImport() -> ProFeatureTeaserItem {
        ProFeatureTeaserItem(
            title: "tripDetail.importSocial".localized,
            subtitle: "pro.socialImportSubtitle".localized,
            icon: "camera.fill",
            color: .pink
        )
    }
}
