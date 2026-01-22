//
//  WishlistViewWrapper.swift
//  Itinero
//
//  Wrapper view to use local WishKit files directly
//

import SwiftUI

// Import WishKit types directly from local files
// Since canImport(WishKit) fails, we'll use the local implementation directly

struct WishlistViewWrapper: View {
    @StateObject private var wishModel = WishModel()
    @State private var selectedWishState: LocalWishState = .all
    @State private var selectedWish: WishResponse? = nil
    
    var body: some View {
        WishlistViewIOS(
            wishModel: wishModel,
            selectedWishState: $selectedWishState
        )
        .navigationTitle("Feature Requests")
        .navigationBarTitleDisplayMode(.large)
    }
}

// Re-export FeedbackListView for compatibility
extension WishlistViewWrapper {
    static var FeedbackListView: some View {
        WishlistViewWrapper()
    }
}



