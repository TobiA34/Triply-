//
//  WishKitLocalization.swift
//  Itinero
//
//  Provides app-localized strings for the WishKit (Feature Requests) screen.
//

import Foundation

enum WishKitLocalization {
    /// Builds a WishKit Configuration.Localization using the app's Localizable.strings (wishlist.* keys).
    static func applyToWishKit() {
        var config = WishKit.config
        config.localization = Configuration.Localization(
            requested: "wishlist.requested".localized,
            pending: "wishlist.pending".localized,
            approved: "wishlist.approved".localized,
            implemented: "wishlist.implemented".localized,
            inReview: "wishlist.inReview".localized,
            planned: "wishlist.planned".localized,
            inProgress: "wishlist.inProgress".localized,
            completed: "wishlist.completed".localized,
            wishlist: "wishlist.featureRequests".localized,
            save: "wishlist.save".localized,
            title: "wishlist.title".localized,
            description: "wishlist.description".localized,
            upvote: "wishlist.upvote".localized,
            info: "wishlist.info".localized,
            youCanOnlyVoteOnce: "wishlist.youCanOnlyVoteOnce".localized,
            youCanNotVoteForAnImplementedWish: "wishlist.youCanNotVoteForAnImplementedWish".localized,
            youCanNotVoteForYourOwnWish: "wishlist.youCanNotVoteForYourOwnWish".localized,
            poweredBy: "wishlist.poweredBy".localized,
            successfullyCreated: "wishlist.successfullyCreated".localized,
            done: "wishlist.done".localized,
            detail: "wishlist.detail".localized,
            featureWishlist: "wishlist.featureRequests".localized,
            confirm: "wishlist.confirm".localized,
            cancel: "wishlist.cancel".localized,
            ok: "wishlist.ok".localized,
            titleOfWish: "wishlist.titleOfWish".localized,
            titleDescriptionCannotBeEmpty: "wishlist.titleDescriptionCannotBeEmpty".localized,
            votes: "wishlist.votes".localized,
            close: "wishlist.close".localized,
            createWish: "wishlist.createWish".localized,
            optional: "wishlist.optional".localized,
            required: "wishlist.required".localized,
            emailRequiredText: "wishlist.emailRequiredText".localized,
            emailFormatWrongText: "wishlist.emailFormatWrongText".localized,
            comments: "wishlist.comments".localized,
            writeAComment: "wishlist.writeAComment".localized,
            admin: "wishlist.admin".localized,
            user: "wishlist.user".localized,
            noFeatureRequests: "wishlist.noFeatureRequests".localized,
            emailOptional: "wishlist.emailOptional".localized,
            emailRequired: "wishlist.emailRequired".localized,
            discardEnteredInformation: "wishlist.discardEnteredInformation".localized,
            addButtonInNavigationBar: "wishlist.addButtonInNavigationBar".localized,
            refresh: "wishlist.refresh".localized,
            refreshing: "wishlist.refreshing".localized,
            loadErrorTitle: "wishlist.loadErrorTitle".localized,
            retry: "wishlist.retry".localized,
            stateAll: "wishlist.stateAll".localized,
            notSupported: "wishlist.notSupported".localized
        )
        WishKit.config = config
    }
}
