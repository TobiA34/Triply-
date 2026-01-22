//
//  ItineroWidgetExtensionBundle.swift
//  ItineroWidgetExtension
//
//  Created by Tobi Adegoroye on 09/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct ItineroWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Main customizable trip widget
        ItineroWidget()
        
        // Enhanced interactive widget (NEW!)
        EnhancedTripWidget()
        
        // Specialized widgets
        UpcomingTripWidget()
        ActiveTripWidget()
        TripStatsWidget()
        
        // Note: Control and Live Activity widgets are optional
        // Uncomment if you want to use them
        //  ItineroWidgetExtensionControl()
        //  ItineroWidgetExtensionLiveActivity()
    }
}
