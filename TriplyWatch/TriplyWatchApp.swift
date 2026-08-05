#if os(watchOS)
import SwiftUI

@main
struct TriplyWatchApp: App {
    @StateObject private var syncStore = WatchSyncStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(syncStore)
        }
    }
}
#endif
