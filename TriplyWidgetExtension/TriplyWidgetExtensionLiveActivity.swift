//
//  ItineroWidgetExtensionLiveActivity.swift
//  ItineroWidgetExtension
//
//  Created by Tobi Adegoroye on 09/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ItineroWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ItineroWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ItineroWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ItineroWidgetExtensionAttributes {
    fileprivate static var preview: ItineroWidgetExtensionAttributes {
        ItineroWidgetExtensionAttributes(name: "World")
    }
}

extension ItineroWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: ItineroWidgetExtensionAttributes.ContentState {
        ItineroWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ItineroWidgetExtensionAttributes.ContentState {
         ItineroWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ItineroWidgetExtensionAttributes.preview) {
   ItineroWidgetExtensionLiveActivity()
} contentStates: {
    ItineroWidgetExtensionAttributes.ContentState.smiley
    ItineroWidgetExtensionAttributes.ContentState.starEyes
}
