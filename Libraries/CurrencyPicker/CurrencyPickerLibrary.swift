//
//  CurrencyPickerLibrary.swift
//  Triply
//
//  A comprehensive currency picker library with search, flags, and grouping
//

import SwiftUI
import Foundation

// MARK: - Enhanced Currency Model
public struct EnhancedCurrency: Identifiable, Hashable, Codable {
    public let id: String
    public let code: String
    public let symbol: String
    public let name: String
    public let flag: String // Emoji flag
    public let region: CurrencyRegion
    public let isPopular: Bool
    
    public init(code: String, symbol: String, name: String, flag: String, region: CurrencyRegion, isPopular: Bool = false) {
        self.id = code
        self.code = code
        self.symbol = symbol
        self.name = name
        self.flag = flag
        self.region = region
        self.isPopular = isPopular
    }
}

// MARK: - Currency Region
public enum CurrencyRegion: String, CaseIterable, Codable {
    case americas = "Americas"
    case europe = "Europe"
    case asia = "Asia"
    case africa = "Africa"
    case middleEast = "Middle East"
    case oceania = "Oceania"
    case other = "Other"
    
    public var icon: String {
        switch self {
        case .americas: return "🌎"
        case .europe: return "🇪🇺"
        case .asia: return "🌏"
        case .africa: return "🌍"
        case .middleEast: return "🕌"
        case .oceania: return "🌊"
        case .other: return "🌐"
        }
    }
}

// MARK: - Currency Database
public class CurrencyDatabase {
    public static let shared = CurrencyDatabase()
    
    public let allCurrencies: [EnhancedCurrency]
    public let popularCurrencies: [EnhancedCurrency]
    
    private init() {
        allCurrencies = [
            // Popular Currencies
            EnhancedCurrency(code: "USD", symbol: "$", name: "US Dollar", flag: "🇺🇸", region: .americas, isPopular: true),
            EnhancedCurrency(code: "EUR", symbol: "€", name: "Euro", flag: "🇪🇺", region: .europe, isPopular: true),
            EnhancedCurrency(code: "GBP", symbol: "£", name: "British Pound", flag: "🇬🇧", region: .europe, isPopular: true),
            EnhancedCurrency(code: "JPY", symbol: "¥", name: "Japanese Yen", flag: "🇯🇵", region: .asia, isPopular: true),
            EnhancedCurrency(code: "AUD", symbol: "A$", name: "Australian Dollar", flag: "🇦🇺", region: .oceania, isPopular: true),
            EnhancedCurrency(code: "CAD", symbol: "C$", name: "Canadian Dollar", flag: "🇨🇦", region: .americas, isPopular: true),
            EnhancedCurrency(code: "CHF", symbol: "CHF", name: "Swiss Franc", flag: "🇨🇭", region: .europe, isPopular: true),
            EnhancedCurrency(code: "CNY", symbol: "¥", name: "Chinese Yuan", flag: "🇨🇳", region: .asia, isPopular: true),
            EnhancedCurrency(code: "INR", symbol: "₹", name: "Indian Rupee", flag: "🇮🇳", region: .asia, isPopular: true),
            EnhancedCurrency(code: "SGD", symbol: "S$", name: "Singapore Dollar", flag: "🇸🇬", region: .asia, isPopular: true),
            
            // Americas
            EnhancedCurrency(code: "MXN", symbol: "Mex$", name: "Mexican Peso", flag: "🇲🇽", region: .americas),
            EnhancedCurrency(code: "BRL", symbol: "R$", name: "Brazilian Real", flag: "🇧🇷", region: .americas),
            EnhancedCurrency(code: "ARS", symbol: "$", name: "Argentine Peso", flag: "🇦🇷", region: .americas),
            EnhancedCurrency(code: "CLP", symbol: "$", name: "Chilean Peso", flag: "🇨🇱", region: .americas),
            EnhancedCurrency(code: "COP", symbol: "$", name: "Colombian Peso", flag: "🇨🇴", region: .americas),
            EnhancedCurrency(code: "PEN", symbol: "S/", name: "Peruvian Sol", flag: "🇵🇪", region: .americas),
            
            // Europe
            EnhancedCurrency(code: "NOK", symbol: "kr", name: "Norwegian Krone", flag: "🇳🇴", region: .europe),
            EnhancedCurrency(code: "SEK", symbol: "kr", name: "Swedish Krona", flag: "🇸🇪", region: .europe),
            EnhancedCurrency(code: "DKK", symbol: "kr", name: "Danish Krone", flag: "🇩🇰", region: .europe),
            EnhancedCurrency(code: "PLN", symbol: "zł", name: "Polish Zloty", flag: "🇵🇱", region: .europe),
            EnhancedCurrency(code: "RUB", symbol: "₽", name: "Russian Ruble", flag: "🇷🇺", region: .europe),
            EnhancedCurrency(code: "TRY", symbol: "₺", name: "Turkish Lira", flag: "🇹🇷", region: .europe),
            EnhancedCurrency(code: "HUF", symbol: "Ft", name: "Hungarian Forint", flag: "🇭🇺", region: .europe),
            EnhancedCurrency(code: "CZK", symbol: "Kč", name: "Czech Koruna", flag: "🇨🇿", region: .europe),
            
            // Asia
            EnhancedCurrency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar", flag: "🇭🇰", region: .asia),
            EnhancedCurrency(code: "KRW", symbol: "₩", name: "South Korean Won", flag: "🇰🇷", region: .asia),
            EnhancedCurrency(code: "TWD", symbol: "NT$", name: "Taiwan Dollar", flag: "🇹🇼", region: .asia),
            EnhancedCurrency(code: "THB", symbol: "฿", name: "Thai Baht", flag: "🇹🇭", region: .asia),
            EnhancedCurrency(code: "MYR", symbol: "RM", name: "Malaysian Ringgit", flag: "🇲🇾", region: .asia),
            EnhancedCurrency(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", flag: "🇮🇩", region: .asia),
            EnhancedCurrency(code: "PHP", symbol: "₱", name: "Philippine Peso", flag: "🇵🇭", region: .asia),
            EnhancedCurrency(code: "VND", symbol: "₫", name: "Vietnamese Dong", flag: "🇻🇳", region: .asia),
            
            // Middle East
            EnhancedCurrency(code: "AED", symbol: "د.إ", name: "UAE Dirham", flag: "🇦🇪", region: .middleEast),
            EnhancedCurrency(code: "SAR", symbol: "﷼", name: "Saudi Riyal", flag: "🇸🇦", region: .middleEast),
            EnhancedCurrency(code: "ILS", symbol: "₪", name: "Israeli Shekel", flag: "🇮🇱", region: .middleEast),
            EnhancedCurrency(code: "QAR", symbol: "﷼", name: "Qatari Riyal", flag: "🇶🇦", region: .middleEast),
            EnhancedCurrency(code: "KWD", symbol: "د.ك", name: "Kuwaiti Dinar", flag: "🇰🇼", region: .middleEast),
            
            // Oceania
            EnhancedCurrency(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar", flag: "🇳🇿", region: .oceania),
            EnhancedCurrency(code: "FJD", symbol: "FJ$", name: "Fijian Dollar", flag: "🇫🇯", region: .oceania),
            
            // Africa
            EnhancedCurrency(code: "ZAR", symbol: "R", name: "South African Rand", flag: "🇿🇦", region: .africa),
            EnhancedCurrency(code: "EGP", symbol: "£", name: "Egyptian Pound", flag: "🇪🇬", region: .africa),
            EnhancedCurrency(code: "NGN", symbol: "₦", name: "Nigerian Naira", flag: "🇳🇬", region: .africa),
            EnhancedCurrency(code: "KES", symbol: "KSh", name: "Kenyan Shilling", flag: "🇰🇪", region: .africa),
        ]
        
        popularCurrencies = allCurrencies.filter { $0.isPopular }
    }
    
    public func currency(for code: String) -> EnhancedCurrency? {
        allCurrencies.first { $0.code == code }
    }
    
    public func search(query: String) -> [EnhancedCurrency] {
        let lowercased = query.lowercased()
        return allCurrencies.filter { currency in
            currency.code.lowercased().contains(lowercased) ||
            currency.name.lowercased().contains(lowercased) ||
            currency.symbol.lowercased().contains(lowercased)
        }
    }
    
    public func currencies(by region: CurrencyRegion) -> [EnhancedCurrency] {
        allCurrencies.filter { $0.region == region }
    }
}

// MARK: - Currency Picker View
public struct CurrencyPickerView: View {
    @Binding var selectedCurrency: EnhancedCurrency
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedRegion: CurrencyRegion? = nil
    @State private var showPopularOnly = false
    
    private let database = CurrencyDatabase.shared
    
    public init(selectedCurrency: Binding<EnhancedCurrency>) {
        self._selectedCurrency = selectedCurrency
    }
    
    private var filteredCurrencies: [EnhancedCurrency] {
        var currencies: [EnhancedCurrency]
        
        if !searchText.isEmpty {
            currencies = database.search(query: searchText)
        } else if let region = selectedRegion {
            currencies = database.currencies(by: region)
        } else if showPopularOnly {
            currencies = database.popularCurrencies
        } else {
            currencies = database.allCurrencies
        }
        
        return currencies.sorted { $0.name < $1.name }
    }
    
    private var groupedCurrencies: [CurrencyRegion: [EnhancedCurrency]] {
        Dictionary(grouping: filteredCurrencies) { $0.region }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Pills
                filterPills
                
                // Currency List
                if filteredCurrencies.isEmpty {
                    emptyState
                } else {
                    currencyList
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search currency...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterPill(
                    title: "Popular",
                    icon: "star.fill",
                    isSelected: showPopularOnly && selectedRegion == nil,
                    action: {
                        showPopularOnly.toggle()
                        selectedRegion = nil
                    }
                )
                
                ForEach(CurrencyRegion.allCases, id: \.self) { region in
                    FilterPill(
                        title: region.rawValue,
                        icon: region.icon,
                        isSelected: selectedRegion == region && !showPopularOnly,
                        action: {
                            if selectedRegion == region {
                                selectedRegion = nil
                            } else {
                                selectedRegion = region
                                showPopularOnly = false
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var currencyList: some View {
        List {
            if showPopularOnly && selectedRegion == nil && searchText.isEmpty {
                Section {
                    ForEach(database.popularCurrencies) { currency in
                        CurrencyRow(
                            currency: currency,
                            isSelected: selectedCurrency.code == currency.code
                        ) {
                            selectedCurrency = currency
                        }
                    }
                } header: {
                    Text("Popular Currencies")
                }
            } else {
                ForEach(CurrencyRegion.allCases, id: \.self) { region in
                    if let currencies = groupedCurrencies[region], !currencies.isEmpty {
                        Section {
                            ForEach(currencies) { currency in
                                CurrencyRow(
                                    currency: currency,
                                    isSelected: selectedCurrency.code == currency.code
                                ) {
                                    selectedCurrency = currency
                                }
                            }
                        } header: {
                            HStack {
                                Text(region.icon)
                                Text(region.rawValue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No currencies found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Currency Row
struct CurrencyRow: View {
    let currency: EnhancedCurrency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
                
                // Currency Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(currency.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Symbol
                Text(currency.symbol)
                    .font(.title3)
                    .foregroundColor(.primary)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if icon != title {
                    Image(systemName: icon)
                        .font(.caption)
                } else {
                    Text(icon)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
#Preview {
    let currency = CurrencyDatabase.shared.allCurrencies.first ?? EnhancedCurrency(code: "USD", symbol: "$", name: "US Dollar", flag: "🇺🇸", region: .americas, isPopular: true)
    CurrencyPickerView(selectedCurrency: .constant(currency))
}




