//
//  FeatureRequestsView.swift
//  Triply
//
//  Feature Requests view using local WishKit implementation
//

import SwiftUI

// Feature Requests View using local WishKit implementation
struct FeatureRequestsView: View {
    @StateObject private var wishModel = WishModel()
    
    var body: some View {
        WishlistViewIOS(wishModel: wishModel)
            .navigationTitle("Feature Requests")
            .navigationBarTitleDisplayMode(.large)
    }
}

