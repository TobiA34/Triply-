//
//  CurrencyConverterView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct CurrencyConverterView: View {
    @StateObject private var converter = CurrencyConverter.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var amount: String = "100"
    @State private var fromCurrency: Currency
    @State private var toCurrency: Currency
    
    init() {
        let defaultCurrency = SettingsManager.shared.currentCurrency
        let eurCurrency = Currency.allCurrencies.first { $0.code == "EUR" } ?? Currency.allCurrencies[0]
        _fromCurrency = State(initialValue: defaultCurrency)
        _toCurrency = State(initialValue: eurCurrency)
    }
    
    var convertedAmount: Double? {
        guard let amountValue = Double(amount) else { return nil }
        return converter.convert(amount: amountValue, from: fromCurrency.code, to: toCurrency.code)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Convert Currency")) {
                    HStack {
                        Text("Amount")
                        Spacer()
                        HStack {
                            Text(fromCurrency.symbol)
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                    
                    Picker("From", selection: $fromCurrency) {
                        ForEach(Currency.allCurrencies, id: \.code) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.name)
                                Spacer()
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(currency)
                        }
                    }
                    
                    Picker("To", selection: $toCurrency) {
                        ForEach(Currency.allCurrencies, id: \.code) { currency in
                            HStack {
                                Text(currency.symbol)
                                Text(currency.name)
                                Spacer()
                                Text(currency.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(currency)
                        }
                    }
                }
                
                if let converted = convertedAmount, let inputAmount = Double(amount), inputAmount > 0 {
                    Section("Result") {
                        VStack(spacing: 12) {
                            HStack {
                                Text("\(fromCurrency.symbol)\(String(format: "%.2f", inputAmount))")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.blue)
                                Text("\(toCurrency.symbol)\(String(format: "%.2f", converted))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            if let rate = converter.getRate(from: fromCurrency.code, to: toCurrency.code) {
                                Text("Rate: 1 \(fromCurrency.code) = \(String(format: "%.4f", rate)) \(toCurrency.code)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let lastUpdated = converter.lastUpdated {
                                Text("Updated: \(lastUpdated, style: .relative)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                
                if let error = converter.errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await converter.fetchLatestRates(baseCurrency: fromCurrency.code)
                        }
                    }) {
                        HStack {
                            if converter.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Refresh Rates")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(converter.isLoading)
                } footer: {
                    Text("Exchange rates are updated automatically. Tap to refresh manually.")
                }
            }
            .navigationTitle("Currency Converter")
            .onAppear {
                // Load cached rates first, then refresh if needed
                fromCurrency = settingsManager.currentCurrency
                Task {
                    await converter.refreshIfNeeded(baseCurrency: fromCurrency.code)
                }
            }
            .onChange(of: settingsManager.currentCurrency) { _, newCurrency in
                fromCurrency = newCurrency
            }
            .onChange(of: fromCurrency) { _, newCurrency in
                // Refresh rates when base currency changes
                Task {
                    await converter.refreshIfNeeded(baseCurrency: newCurrency.code)
                }
            }
        }
    }
}

#Preview {
    CurrencyConverterView()
}

