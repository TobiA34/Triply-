//
//  FeatureRequestsView.swift
//  Itinero
//
//  Feature Requests view using local WishKit implementation
//

import SwiftUI

// Feature Requests View using local WishKit implementation
struct FeatureRequestsView: View {
    var body: some View {
        WishKit.FeedbackListView()
            .navigationTitle("Feature Requests")
            .navigationBarTitleDisplayMode(.large)
    }
}

