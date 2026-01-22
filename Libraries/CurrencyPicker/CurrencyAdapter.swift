//
//  CurrencyAdapter.swift
//  Itinero
//
//  Adapter to bridge between old Currency model and new EnhancedCurrency
//

import Foundation

extension Currency {
    /// Convert old Currency to EnhancedCurrency
    var enhanced: EnhancedCurrency {
        let database = CurrencyDatabase.shared
        return database.currency(for: self.code) ?? EnhancedCurrency(
            code: self.code,
            symbol: self.symbol,
            name: self.name,
            flag: "💵",
            region: .other
        )
    }
}

extension EnhancedCurrency {
    /// Convert EnhancedCurrency to old Currency model
    var legacy: Currency {
        Currency(code: self.code, symbol: self.symbol, name: self.name)
    }
}



