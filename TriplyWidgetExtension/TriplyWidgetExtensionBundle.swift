//
//  TriplyWidgetExtensionBundle.swift
//  TriplyWidgetExtension
//
//  Created by Tobi Adegoroye on 28/01/2026.
//

import WidgetKit
import SwiftUI

@main
struct TriplyWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Main trip widgets
        ItineroWidget()
        UpcomingTripWidget()
        ActiveTripWidget()
        TripStatsWidget()
    }
}
