import Foundation

struct WatchAppPayload: Codable, Equatable {
    var generatedAt: Date
    var trips: [WatchTripSnapshot]
}

struct WatchTripSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date
    var category: String
    var notes: String
    var budget: Double?
    var lastModified: Date
    var destinations: [WatchDestinationSnapshot]
    var itineraryItems: [WatchItineraryItemSnapshot]
    var packingItems: [WatchPackingItemSnapshot]
    var expenses: [WatchExpenseSnapshot]

    var isUpcoming: Bool {
        startDate > Date()
    }

    var isPast: Bool {
        endDate < Date()
    }

    var isCurrent: Bool {
        let now = Date()
        return startDate <= now && endDate >= now
    }

    var totalExpenseAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var packedItemCount: Int {
        packingItems.filter(\.isPacked).count
    }
}

struct WatchDestinationSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var address: String
    var notes: String
}

struct WatchItineraryItemSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var day: Int
    var date: Date
    var title: String
    var details: String
    var time: String
    var location: String
    var category: String
    var isBooked: Bool
}

struct WatchPackingItemSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var category: String
    var quantity: Int
    var notes: String
    var isPacked: Bool
    var isEssential: Bool
}

struct WatchExpenseSnapshot: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var currencyCode: String
    var date: Date
    var notes: String
}
