//
//  Expense.swift
//  Triply
//
//  Created on 2024
//

import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var category: String
    var date: Date
    var notes: String
    var receiptImageData: Data?
    var currencyCode: String
    
    @Relationship(deleteRule: .nullify) var documents: [TripDocument]?
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String = "Other",
        date: Date = Date(),
        notes: String = "",
        receiptImageData: Data? = nil,
        currencyCode: String = "USD"
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.receiptImageData = receiptImageData
        self.currencyCode = currencyCode
    }
}

