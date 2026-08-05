#if os(watchOS)
import Foundation
import WatchConnectivity

@MainActor
final class WatchSyncStore: NSObject, ObservableObject {
    static let cacheKey = "triply.watch.payload"

    @Published private(set) var payload = WatchAppPayload(generatedAt: .distantPast, trips: [])

    private let decoder = JSONDecoder()

    override init() {
        super.init()
        decoder.dateDecodingStrategy = .iso8601
        loadCachedPayload()
        activateSession()
    }

    var trips: [WatchTripSnapshot] {
        payload.trips
    }

    var currentTrips: [WatchTripSnapshot] {
        trips.filter(\.isCurrent).sorted { $0.endDate < $1.endDate }
    }

    var upcomingTrips: [WatchTripSnapshot] {
        trips.filter(\.isUpcoming).sorted { $0.startDate < $1.startDate }
    }

    var pastTrips: [WatchTripSnapshot] {
        trips.filter(\.isPast).sorted { $0.startDate > $1.startDate }
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func loadCachedPayload() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        applyPayloadData(data)
    }

    private func applyPayloadData(_ data: Data) {
        guard let decoded = try? decoder.decode(WatchAppPayload.self, from: data) else { return }
        payload = decoded
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
    }
}

extension WatchSyncStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("Watch session activation failed: \(error)")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["trip_payload"] as? Data else { return }
        Task { @MainActor in
            self.applyPayloadData(data)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["trip_payload"] as? Data else { return }
        Task { @MainActor in
            self.applyPayloadData(data)
        }
    }
}
#endif
