//
//  DestinationSearchView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI

struct DestinationSearchView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var searchManager: DestinationSearchManager
    @Binding var selectedDestinations: [SearchResult]
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search destinations...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _, newValue in
                            searchManager.searchDestinations(query: newValue)
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchManager.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Results
                if searchManager.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchManager.searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No destinations found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Destinations")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ForEach(searchManager.popularDestinations) { destination in
                            DestinationRowView(
                                destination: destination,
                                isSelected: selectedDestinations.contains { $0.id == destination.id }
                            ) {
                                toggleDestination(destination)
                            }
                        }
                    }
                } else {
                    List {
                        ForEach(searchManager.searchResults) { result in
                            DestinationRowView(
                                destination: result,
                                isSelected: selectedDestinations.contains { $0.id == result.id }
                            ) {
                                toggleDestination(result)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Destinations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                searchManager.clearSearch()
            }
        }
    }
    
    private func toggleDestination(_ destination: SearchResult) {
        if let index = selectedDestinations.firstIndex(where: { $0.id == destination.id }) {
            selectedDestinations.remove(at: index)
        } else {
            selectedDestinations.append(destination)
        }
    }
}

struct DestinationRowView: View {
    let destination: SearchResult
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(destination.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DestinationSearchView(
        searchManager: DestinationSearchManager(),
        selectedDestinations: .constant([])
    )
}



