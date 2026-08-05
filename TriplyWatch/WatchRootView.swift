#if os(watchOS)
import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var syncStore: WatchSyncStore

    var body: some View {
        NavigationStack {
            List {
                if syncStore.trips.isEmpty {
                    Section("Get Started") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open Triply on your iPhone to sync your latest trips to Apple Watch.")
                                .font(.footnote)
                            Text("Once synced, your trips, itinerary, packing list, and expenses will show up here.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    tripSection("Current", trips: syncStore.currentTrips)
                    tripSection("Upcoming", trips: syncStore.upcomingTrips)
                    tripSection("Past", trips: syncStore.pastTrips)
                }
            }
            .navigationTitle("Triply")
        }
    }

    @ViewBuilder
    private func tripSection(_ title: String, trips: [WatchTripSnapshot]) -> some View {
        if !trips.isEmpty {
            Section(title) {
                ForEach(trips) { trip in
                    NavigationLink {
                        WatchTripDetailView(trip: trip)
                    } label: {
                        WatchTripRow(trip: trip)
                    }
                }
            }
        }
    }
}

private struct WatchTripRow: View {
    let trip: WatchTripSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.headline)
            Text(dateRangeText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(trip.destinations.count)", systemImage: "mappin.and.ellipse")
                Label("\(trip.itineraryItems.count)", systemImage: "list.bullet.rectangle")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var dateRangeText: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: trip.startDate, to: trip.endDate)
    }
}

private struct WatchTripDetailView: View {
    let trip: WatchTripSnapshot

    var body: some View {
        List {
            Section("Overview") {
                detailRow("Dates", value: dateRangeText)
                detailRow("Category", value: trip.category)
                if let budget = trip.budget {
                    detailRow("Budget", value: budgetText(budget))
                }
                detailRow("Spent", value: budgetText(trip.totalExpenseAmount))
                detailRow("Packed", value: "\(trip.packedItemCount)/\(trip.packingItems.count)")
            }

            if !trip.notes.isEmpty {
                Section("Notes") {
                    Text(trip.notes)
                        .font(.footnote)
                }
            }

            if !trip.destinations.isEmpty {
                Section("Destinations") {
                    ForEach(trip.destinations) { destination in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(destination.name)
                            if !destination.address.isEmpty {
                                Text(destination.address)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !trip.itineraryItems.isEmpty {
                Section("Itinerary") {
                    ForEach(trip.itineraryItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.body.weight(.semibold))
                            if !item.time.isEmpty || !item.location.isEmpty {
                                Text([item.time, item.location].filter { !$0.isEmpty }.joined(separator: " • "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if !trip.packingItems.isEmpty {
                Section("Packing") {
                    ForEach(trip.packingItems) { item in
                        Label {
                            Text(item.name)
                        } icon: {
                            Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isPacked ? .green : .secondary)
                        }
                    }
                }
            }

            if !trip.expenses.isEmpty {
                Section("Expenses") {
                    ForEach(trip.expenses) { expense in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                            Text("\(budgetText(expense.amount, code: expense.currencyCode)) • \(expense.category)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(trip.name)
    }

    @ViewBuilder
    private func detailRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }

    private var dateRangeText: String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: trip.startDate, to: trip.endDate)
    }

    private func budgetText(_ amount: Double, code: String = Locale.current.currency?.identifier ?? "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}
#endif
