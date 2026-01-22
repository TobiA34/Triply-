//
//  SmartPackingGeneratorView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct SmartPackingGeneratorView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var aiFoundation = AppleAIFoundation.shared
    @StateObject private var iap = IAPManager.shared
    
    @State private var isGenerating = false
    @State private var generatedItems: [PackingItem] = []
    @State private var selectedCategories: Set<String> = Set(["all"])
    @State private var addedItemIds: Set<UUID> = []
    @State private var showingAddItem = false
    
    var body: some View {
        if !iap.isPro {
            PaywallGateView(
                featureName: "Smart Packing Generator",
                featureDescription: "Get AI-powered packing suggestions based on your destination, weather, trip type, and duration.",
                icon: "suitcase.fill",
                iconColor: .purple
            )
            .navigationTitle("Smart Packing")
        } else {
            packingContent
        }
    }
    
    private var packingContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "suitcase.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.purple)
                    
                    Text("Smart Packing List")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("AI-powered suggestions based on your trip")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Generate Button
                    Button {
                        generatePackingList()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.headline)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Packing List")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating)
                    
                    // Add Custom Item Button
                    Button {
                        showingAddItem = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Item")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Category Filters and Add All Button
                if !generatedItems.isEmpty {
                    VStack(spacing: 12) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryFilterButton(
                                    title: "All",
                                    isSelected: selectedCategories.contains("all")
                                ) {
                                    if selectedCategories.contains("all") {
                                        selectedCategories.removeAll()
                                    } else {
                                        selectedCategories = ["all"]
                                    }
                                }
                                
                                ForEach(uniqueCategories, id: \.self) { category in
                                    CategoryFilterButton(
                                        title: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        if selectedCategories.contains("all") {
                                            selectedCategories = [category]
                                        } else if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                        
                                        if selectedCategories.isEmpty {
                                            selectedCategories = ["all"]
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Add All Button
                        if unaddedFilteredItemsCount > 0 {
                            Button {
                                addAllFilteredItems()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add All (\(unaddedFilteredItemsCount) items)")
                                        .fontWeight(.medium)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Packing Items
                if generatedItems.isEmpty && !isGenerating {
                    VStack(spacing: 12) {
                        Image(systemName: "suitcase")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No packing list yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Generate AI-powered suggestions or add your own items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            PackingItemRow(
                                item: item,
                                isAdded: addedItemIds.contains(item.id),
                                onAddToList: { addItemToList(item) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Smart Packing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddItem) {
            AddPackingItemView(trip: trip)
        }
        .onAppear {
            loadExistingItems()
        }
    }
    
    private var uniqueCategories: [String] {
        Array(Set(generatedItems.map { $0.category })).sorted()
    }
    
    private var filteredItems: [PackingItem] {
        if selectedCategories.contains("all") {
            return generatedItems
        }
        return generatedItems.filter { selectedCategories.contains($0.category) }
    }
    
    private var unaddedFilteredItemsCount: Int {
        filteredItems.filter { !addedItemIds.contains($0.id) }.count
    }
    
    private func loadExistingItems() {
        // Check which generated items have already been added to the trip's packing list
        let existingItemNames = Set((trip.packingList ?? []).map { $0.name })
        for item in generatedItems {
            if existingItemNames.contains(item.name) {
                addedItemIds.insert(item.id)
            }
        }
    }
    
    private func generatePackingList() {
        isGenerating = true
        addedItemIds.removeAll()
        
        Task {
            // Generate packing list based on trip details
            let items = await generateSmartPackingItems()
            
            await MainActor.run {
                // Don't automatically add items - let user select which ones to add
                generatedItems = items
                isGenerating = false
                HapticManager.shared.success()
            }
        }
    }
    
    private func addItemToList(_ item: PackingItem) {
        // Check if item already exists in trip's packing list
        let existingItems = trip.packingList ?? []
        if existingItems.contains(where: { $0.id == item.id || $0.name == item.name }) {
            HapticManager.shared.error()
            return
        }
        
        // Create a new PackingItem instance for the trip's list
        let newItem = PackingItem(
            id: UUID(),
            name: item.name,
            isPacked: false,
            category: item.category,
            order: existingItems.count
        )
        
        modelContext.insert(newItem)
        
        if trip.packingList == nil {
            trip.packingList = []
        }
        trip.packingList?.append(newItem)
        
        // Mark as added
        addedItemIds.insert(item.id)
        
        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            print("Failed to add packing item: \(error)")
            HapticManager.shared.error()
        }
    }
    
    private func addAllFilteredItems() {
        let itemsToAdd = filteredItems.filter { !addedItemIds.contains($0.id) }
        let existingItems = trip.packingList ?? []
        let existingItemNames = Set(existingItems.map { $0.name })
        
        var addedCount = 0
        var order = existingItems.count
        
        for item in itemsToAdd {
            // Skip if already exists
            if existingItemNames.contains(item.name) {
                addedItemIds.insert(item.id)
                continue
            }
            
            let newItem = PackingItem(
                id: UUID(),
                name: item.name,
                isPacked: false,
                category: item.category,
                order: order
            )
            
            modelContext.insert(newItem)
            
            if trip.packingList == nil {
                trip.packingList = []
            }
            trip.packingList?.append(newItem)
            addedItemIds.insert(item.id)
            addedCount += 1
            order += 1
        }
        
        do {
            try modelContext.save()
            if addedCount > 0 {
                HapticManager.shared.success()
            }
        } catch {
            print("Failed to add packing items: \(error)")
            HapticManager.shared.error()
        }
    }
    
    private func generateSmartPackingItems() async -> [PackingItem] {
        // AI-powered packing list generation
        var items: [PackingItem] = []
        
        // Base items for all trips
        items.append(contentsOf: [
            PackingItem(name: "Passport", isPacked: false, category: "Documents", order: 0),
            PackingItem(name: "Travel Insurance", isPacked: false, category: "Documents", order: 1),
            PackingItem(name: "Phone Charger", isPacked: false, category: "Electronics", order: 2),
            PackingItem(name: "Power Adapter", isPacked: false, category: "Electronics", order: 3),
        ])
        
        var order = 4
        
        // Category-specific items
        switch trip.category.lowercased() {
        case "beach", "vacation":
            items.append(contentsOf: [
                PackingItem(name: "Swimsuit", isPacked: false, category: "Clothing", order: order),
                PackingItem(name: "Sunscreen", isPacked: false, category: "Toiletries", order: order + 1),
                PackingItem(name: "Beach Towel", isPacked: false, category: "Accessories", order: order + 2),
                PackingItem(name: "Sunglasses", isPacked: false, category: "Accessories", order: order + 3),
            ])
            order += 4
        case "business":
            items.append(contentsOf: [
                PackingItem(name: "Business Attire", isPacked: false, category: "Clothing", order: order),
                PackingItem(name: "Laptop", isPacked: false, category: "Electronics", order: order + 1),
                PackingItem(name: "Notebook", isPacked: false, category: "Documents", order: order + 2),
            ])
            order += 3
        case "adventure", "hiking":
            items.append(contentsOf: [
                PackingItem(name: "Hiking Boots", isPacked: false, category: "Footwear", order: order),
                PackingItem(name: "Backpack", isPacked: false, category: "Accessories", order: order + 1),
                PackingItem(name: "Water Bottle", isPacked: false, category: "Accessories", order: order + 2),
                PackingItem(name: "First Aid Kit", isPacked: false, category: "Health", order: order + 3),
            ])
            order += 4
        default:
            items.append(contentsOf: [
                PackingItem(name: "Comfortable Shoes", isPacked: false, category: "Footwear", order: order),
                PackingItem(name: "Weather-Appropriate Clothing", isPacked: false, category: "Clothing", order: order + 1),
            ])
            order += 2
        }
        
        // Duration-based items
        if trip.duration > 7 {
            items.append(contentsOf: [
                PackingItem(name: "Extra Underwear", isPacked: false, category: "Clothing", order: order),
                PackingItem(name: "Laundry Detergent", isPacked: false, category: "Toiletries", order: order + 1),
            ])
        }
        
        return items
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct PackingItemRow: View {
    @Bindable var item: PackingItem
    let isAdded: Bool
    let onAddToList: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if isAdded {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Added")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                Button {
                    onAddToList()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to List")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(isAdded ? Color.green.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        SmartPackingGeneratorView(trip: TripModel(
            name: "Paris Trip",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7)
        ))
    }
}

