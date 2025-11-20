//
//  PackingListView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI
import SwiftData

struct PackingListView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @StateObject private var packingAssistant = PackingAssistant.shared
    @StateObject private var weatherManager = WeatherManager.shared
    @State private var showingSuggestions = false
    @State private var showingAddItem = false
    @State private var selectedCategory: String? = nil
    
    var packingItems: [PackingItem] {
        trip.packingList?.sorted(by: { $0.order < $1.order }) ?? []
    }
    
    var itemsByCategory: [String: [PackingItem]] {
        Dictionary(grouping: packingItems, by: { $0.category })
    }
    
    var packedCount: Int {
        packingItems.filter { $0.isPacked }.count
    }
    
    var totalCount: Int {
        packingItems.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Card
                if totalCount > 0 {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Packing Progress")
                                    .font(.headline)
                                Text("\(packedCount) of \(totalCount) items packed")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            CircularProgressView(progress: Double(packedCount) / Double(max(totalCount, 1)))
                                .frame(width: 60, height: 60)
                        }
                        
                        ProgressView(value: Double(packedCount), total: Double(totalCount))
                            .tint(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingSuggestions = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Smart Suggestions")
                        }
                        .font(.headline)
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
                    
                    Button(action: { showingAddItem = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Item")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Category Filter
                if !itemsByCategory.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(Array(itemsByCategory.keys.sorted()), id: \.self) { category in
                                CategoryChip(title: category, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Packing Items
                if packingItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "suitcase")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No items yet")
                            .font(.headline)
                        Text("Get smart suggestions based on your trip and weather")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    let filteredItems = selectedCategory == nil ? 
                        packingItems : 
                        packingItems.filter { $0.category == selectedCategory }
                    
                    ForEach(filteredItems) { item in
                        PackingItemRowView(item: item, trip: trip, modelContext: modelContext)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Packing List")
        .sheet(isPresented: $showingSuggestions) {
            PackingSuggestionsView(trip: trip, weatherForecasts: weatherManager.forecasts)
        }
        .sheet(isPresented: $showingAddItem) {
            AddPackingItemView(trip: trip)
        }
        .onAppear {
            // Load weather for suggestions
            if let firstDestination = trip.destinations?.first {
                Task {
                    await weatherManager.fetchWeather(
                        for: firstDestination.name,
                        startDate: trip.startDate,
                        endDate: trip.endDate
                    )
                }
            }
        }
    }
    
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}

struct PackingItemRowView: View {
    @Bindable var item: PackingItem
    let trip: TripModel
    let modelContext: ModelContext
    @State private var showingEdit = false
    
    var body: some View {
        HStack {
            Button(action: {
                item.isPacked.toggle()
                trip.notes = trip.notes // Force change detection
                try? modelContext.save()
            }) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isPacked ? .green : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(item.isPacked)
                    .foregroundColor(item.isPacked ? .secondary : .primary)
                
                Text(item.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                Button(action: { showingEdit = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive, action: {
                    trip.packingList?.removeAll { $0.id == item.id }
                    trip.notes = trip.notes // Force change detection
                    try? modelContext.save()
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(item.isPacked ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingEdit) {
            EditPackingItemView(item: item)
        }
    }
}

struct PackingSuggestionsView: View {
    @Environment(\.dismiss) var dismiss
    let trip: TripModel
    let weatherForecasts: [WeatherForecast]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var assistant = PackingAssistant.shared
    
    var suggestions: [PackingSuggestion] {
        assistant.generateSuggestions(for: trip, weatherForecasts: weatherForecasts)
    }
    
    var essentialItems: [PackingSuggestion] {
        suggestions.filter { $0.priority == .essential }
    }
    
    var recommendedItems: [PackingSuggestion] {
        suggestions.filter { $0.priority == .recommended }
    }
    
    var optionalItems: [PackingSuggestion] {
        suggestions.filter { $0.priority == .optional }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Smart packing suggestions based on your trip details and weather forecast.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Essential Items
                    if !essentialItems.isEmpty {
                        SuggestionSection(title: "Essential", items: essentialItems, color: .red, trip: trip, modelContext: modelContext)
                    }
                    
                    // Recommended Items
                    if !recommendedItems.isEmpty {
                        SuggestionSection(title: "Recommended", items: recommendedItems, color: .orange, trip: trip, modelContext: modelContext)
                    }
                    
                    // Optional Items
                    if !optionalItems.isEmpty {
                        SuggestionSection(title: "Optional", items: optionalItems, color: .blue, trip: trip, modelContext: modelContext)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Packing Suggestions")
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
}

struct SuggestionSection: View {
    let title: String
    let items: [PackingSuggestion]
    let color: Color
    let trip: TripModel
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ForEach(Array(items.enumerated()), id: \.offset) { index, suggestion in
                Button(action: {
                    addItem(from: suggestion)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.item)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(suggestion.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(color)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }
    
    private func addItem(from suggestion: PackingSuggestion) {
        let existingItems = trip.packingList ?? []
        if !existingItems.contains(where: { $0.name == suggestion.item }) {
            let newItem = PackingItem(
                name: suggestion.item,
                isPacked: false,
                category: suggestion.category,
                order: existingItems.count
            )
            modelContext.insert(newItem)
            
            if trip.packingList == nil {
                trip.packingList = []
            }
            trip.packingList?.append(newItem)
            
            // Update a property to trigger SwiftData change detection
            trip.notes = trip.notes // Force change detection
            
            try? modelContext.save()
        }
    }
}

struct AddPackingItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    @State private var name: String = ""
    @State private var category: String = "General"
    @State private var isPacked: Bool = false
    
    private let categories = ["Clothing", "Electronics", "Toiletries", "Documents", "Health", "Accessories", "Footwear", "Essentials", "General"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Toggle("Mark as Packed", isOn: $isPacked)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let existingItems = trip.packingList ?? []
                        let newItem = PackingItem(
                            name: name,
                            isPacked: isPacked,
                            category: category,
                            order: existingItems.count
                        )
                        modelContext.insert(newItem)
                        
                        if trip.packingList == nil {
                            trip.packingList = []
                        }
                        trip.packingList?.append(newItem)
                        
                        // Update a property to trigger SwiftData change detection
                        trip.notes = trip.notes
                        
                        do {
                            try modelContext.save()
                            HapticManager.shared.success()
                        } catch {
                            print("Failed to save packing item: \(error)")
                            HapticManager.shared.error()
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct EditPackingItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: PackingItem
    
    @State private var name: String
    @State private var category: String
    @State private var isPacked: Bool
    
    private let categories = ["Clothing", "Electronics", "Toiletries", "Documents", "Health", "Accessories", "Footwear", "Essentials", "General"]
    
    init(item: PackingItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _isPacked = State(initialValue: item.isPacked)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Toggle("Packed", isOn: $isPacked)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.name = name
                        item.category = category
                        item.isPacked = isPacked
                        
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to save packing item: \(error)")
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PackingListView(trip: TripModel(
        name: "Test Trip",
        startDate: Date(),
        endDate: Date()
    ))
    .modelContainer(for: [TripModel.self, PackingItem.self], inMemory: true)
}

