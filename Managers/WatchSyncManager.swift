#if os(iOS)
import Foundation
import SwiftData
import WatchConnectivity

@MainActor
final class WatchSyncManager: NSObject, ObservableObject {
    static let shared = WatchSyncManager()

    private let encoder = JSONEncoder()
    private var didActivateSession = false

    private override init() {
        super.init()
        encoder.dateEncodingStrategy = .iso8601
    }

    func activateIfNeeded() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard !didActivateSession else { return }
        didActivateSession = true
        session.delegate = self
        session.activate()
    }

    func pushTrips(_ trips: [TripModel]) {
        activateIfNeeded()

        guard WCSession.default.activationState == .activated else { return }

        let payload = WatchAppPayload(
            generatedAt: Date(),
            trips: trips
                .sorted { $0.startDate < $1.startDate }
                .map(makeSnapshot(from:))
        )

        do {
            let data = try encoder.encode(payload)
            try WCSession.default.updateApplicationContext(["trip_payload": data])
        } catch {
            print("Watch sync failed: \(error)")
        }
    }

    func pushCurrentSnapshot() {
        guard let context = DatabaseManager.shared.mainContext else { return }
        let descriptor = FetchDescriptor<TripModel>(sortBy: [SortDescriptor(\.startDate, order: .forward)])
        let trips = (try? context.fetch(descriptor)) ?? []
        pushTrips(trips)
    }

    private func makeSnapshot(from trip: TripModel) -> WatchTripSnapshot {
        WatchTripSnapshot(
            id: trip.id,
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            category: trip.category,
            notes: trip.notes,
            budget: trip.budget,
            lastModified: trip.lastModified,
            destinations: (trip.destinations ?? [])
                .sorted { $0.order < $1.order }
                .map {
                    WatchDestinationSnapshot(
                        id: $0.id,
                        name: $0.name,
                        address: $0.address,
                        notes: $0.notes
                    )
                },
            itineraryItems: (trip.itinerary ?? [])
                .sorted {
                    if $0.day == $1.day {
                        return $0.order < $1.order
                    }
                    return $0.day < $1.day
                }
                .map {
                    WatchItineraryItemSnapshot(
                        id: $0.id,
                        day: $0.day,
                        date: $0.date,
                        title: $0.title,
                        details: $0.details,
                        time: $0.time,
                        location: $0.location,
                        category: $0.category,
                        isBooked: $0.isBooked
                    )
                },
            packingItems: (trip.packingList ?? [])
                .sorted { $0.order < $1.order }
                .map {
                    WatchPackingItemSnapshot(
                        id: $0.id,
                        name: $0.name,
                        category: $0.category,
                        quantity: $0.quantity,
                        notes: $0.notes,
                        isPacked: $0.isPacked,
                        isEssential: $0.isEssential
                    )
                },
            expenses: (trip.expenses ?? [])
                .sorted { $0.date > $1.date }
                .map {
                    WatchExpenseSnapshot(
                        id: $0.id,
                        title: $0.title,
                        amount: $0.amount,
                        category: $0.category,
                        currencyCode: $0.currencyCode,
                        date: $0.date,
                        notes: $0.notes
                    )
                }
        )
    }
}

extension WatchSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("Watch session activation failed: \(error)")
        }
        Task { @MainActor in
            self.pushCurrentSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            WCSession.default.activate()
        }
    }
}
#endif
