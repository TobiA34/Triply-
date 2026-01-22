//
//  CountryPickerView.swift
//  Itinero
//
//  Country picker with search and region filtering
//

import SwiftUI

struct CountryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCountry: Country?
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil
    @State private var refreshID = UUID()
    
    private let countryManager = CountryManager.shared
    
    var filteredCountries: [Country] {
        if !searchText.isEmpty {
            return countryManager.searchCountries(searchText)
        } else if let region = selectedRegion {
            return countryManager.countriesByRegion(region)
        } else {
            return countryManager.countries
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBarView
                
                if searchText.isEmpty {
                    regionFilterView
                }
                
                countriesListView
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .id(refreshID)
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var regionFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                regionButton(title: "All", isSelected: selectedRegion == nil) {
                    selectedRegion = nil
                }
                
                ForEach(countryManager.regions, id: \.self) { region in
                    regionButton(title: region, isSelected: selectedRegion == region) {
                        selectedRegion = region
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private func regionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
    
    private var countriesListView: some View {
        Group {
            if filteredCountries.isEmpty {
                emptyStateView
            } else {
                countriesListContent
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No countries found")
                .font(.headline)
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var countriesListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredCountries) { country in
                    CountryRowView(
                        country: country,
                        isSelected: selectedCountry?.id == country.id
                    ) {
                        selectedCountry = country
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CountryRowView: View {
    let country: Country
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(country.flag)
                    .font(.title2)
                
                Text(country.localizedName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        Divider()
    }
}