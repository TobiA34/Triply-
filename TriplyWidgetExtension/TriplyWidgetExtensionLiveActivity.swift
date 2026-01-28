//
//  TriplyWidgetExtensionLiveActivity.swift
//  TriplyWidgetExtension
//
//  Created by Tobi Adegoroye on 28/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TriplyWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TriplyWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TriplyWidgetExtensionAttributes.self) { context in
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

extension TriplyWidgetExtensionAttributes {
    fileprivate static var preview: TriplyWidgetExtensionAttributes {
        TriplyWidgetExtensionAttributes(name: "World")
    }
}

extension TriplyWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: TriplyWidgetExtensionAttributes.ContentState {
        TriplyWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TriplyWidgetExtensionAttributes.ContentState {
         TriplyWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TriplyWidgetExtensionAttributes.preview) {
   TriplyWidgetExtensionLiveActivity()
} contentStates: {
    TriplyWidgetExtensionAttributes.ContentState.smiley
    TriplyWidgetExtensionAttributes.ContentState.starEyes
}
