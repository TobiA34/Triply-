//
//  PackingListView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import PhotosUI

struct PackingListView: View {
    @Bindable var trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @Query(sort: \TripModel.startDate, order: .reverse) private var allTrips: [TripModel]
    @StateObject private var packingAssistant = PackingAssistant.shared
    @StateObject private var weatherManager = WeatherManager.shared
    @State private var showingSuggestions = false
    @State private var showingAddItem = false
    @State private var showingTemplates = false
    @State private var showingDuplicateFrom = false
    @State private var showingExport = false
    @State private var selectedCategory: String? = nil
    @State private var viewMode: ViewMode = .category
    @State private var selectedBag: String? = nil
    @State private var limitMessage: String?
    @State private var showingEmbeddedExpenses = false
    
    enum ViewMode: String, CaseIterable {
        case category = "Category"
        case bag = "Bag"
        case essential = "Essential First"
    }
    
    var packingItems: [PackingItem] {
        let items = trip.packingList?.sorted(by: { $0.order < $1.order }) ?? []
        switch viewMode {
        case .essential:
            return items.sorted { item1, item2 in item1.isEssential && !item2.isEssential }
        default:
            return items
        }
    }
    
    var itemsByCategory: [String: [PackingItem]] {
        Dictionary(grouping: packingItems, by: { $0.category })
    }
    
    var itemsByBag: [String: [PackingItem]] {
        Dictionary(grouping: packingItems.filter { ($0.bagName ?? "").isEmpty == false }, by: { $0.bagName ?? "Unassigned" })
    }
    
    var packedCount: Int {
        packingItems.filter { $0.isPacked }.count
    }
    
    var totalCount: Int {
        packingItems.count
    }
    
    var totalWeight: Double {
        packingItems.compactMap { item in
            item.estimatedWeight.map { $0 * Double(item.quantity) }
        }.reduce(0, +)
    }
    
    var uniqueBags: [String] {
        let bagNames: [String] = packingItems.compactMap { $0.bagName }
        let nonEmpty = bagNames.filter { !$0.isEmpty }
        let unique = Set(nonEmpty)
        return Array(unique).sorted()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced Progress Card
                if totalCount > 0 {
                    PackingProgressCardView(
                        packedCount: packedCount,
                        totalCount: totalCount,
                        totalWeight: totalWeight
                    )
                }

                // Lightweight expense summary so packing + expenses feel unified
                EmbeddedExpenseSummaryView(trip: trip) {
                    showingEmbeddedExpenses = true
                }
                
                // Enhanced Action Buttons
                PackingActionButtonsView(
                    showingSuggestions: $showingSuggestions,
                    showingAddItem: $showingAddItem,
                    showingTemplates: $showingTemplates,
                    showingDuplicateFrom: $showingDuplicateFrom,
                    showingExport: $showingExport
                )
                
                // View Mode Picker
                if !packingItems.isEmpty {
                    PackingViewModePickerView(viewMode: $viewMode)
                }
                
                // Category/Bag Filter
                PackingFilterSectionView(
                    viewMode: viewMode,
                    selectedCategory: $selectedCategory,
                    selectedBag: $selectedBag,
                    itemsByCategory: itemsByCategory,
                    uniqueBags: uniqueBags
                )
                
                // Packing Items
                PackingItemsSectionView(
                    packingItems: packingItems,
                    viewMode: viewMode,
                    selectedCategory: selectedCategory,
                    selectedBag: selectedBag,
                    itemsByCategory: itemsByCategory,
                    itemsByBag: itemsByBag,
                    trip: trip,
                    modelContext: modelContext
                )
            }
            .padding(.vertical)
        }
        .navigationTitle("Packing List")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingSuggestions = true }) {
                        Label("Smart Suggestions", systemImage: "sparkles")
                    }
                    Button(action: { showingTemplates = true }) {
                        Label("Templates", systemImage: "list.bullet.rectangle")
                    }
                    Button(action: { showingDuplicateFrom = true }) {
                        Label("Copy from Trip", systemImage: "doc.on.doc")
                    }
                    Button(action: { showingExport = true }) {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingSuggestions) {
            PackingSuggestionsView(trip: trip, weatherForecasts: weatherManager.forecasts)
        }
        .sheet(isPresented: $showingTemplates) {
            PackingTemplatesView(trip: trip)
        }
        .sheet(isPresented: $showingDuplicateFrom) {
            DuplicatePackingListView(trip: trip, allTrips: allTrips.filter { $0.id != trip.id })
        }
        .sheet(isPresented: $showingExport) {
            SharePackingListView(trip: trip, items: packingItems)
        }
        .fullScreenCover(isPresented: $showingAddItem) {
            AddPackingItemView(trip: trip)
        }
        .sheet(isPresented: $showingEmbeddedExpenses) {
            NavigationStack {
                ExpenseTrackingView(trip: trip)
            }
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
        .alert("Limit Reached", isPresented: Binding(
            get: { limitMessage != nil },
            set: { if !$0 { limitMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(limitMessage ?? "")
        }
    }
}

// MARK: - Helper Views to Reduce Type-Checking Complexity

private struct EmbeddedExpenseSummaryView: View {
    @Bindable var trip: TripModel
    @EnvironmentObject var themeManager: ThemeManager
    private let settingsManager = SettingsManager.shared
    var onOpenExpenses: () -> Void

    private var totalExpenses: Double {
        trip.expenses?.reduce(0) { $0 + $1.amount } ?? 0
    }

    private var budgetRemaining: Double? {
        guard let budget = trip.budget else { return nil }
        return budget - totalExpenses
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expenses")
                        .font(.headline)
                        .foregroundColor(themeManager.currentPalette.text)
                    Text(settingsManager.formatAmount(totalExpenses))
                        .font(.title3.weight(.semibold))
                        .foregroundColor(themeManager.currentPalette.accent)

                    if let remaining = budgetRemaining {
                        Text("Remaining: \(settingsManager.formatAmount(remaining))")
                            .font(.caption)
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    }
                }
                Spacer()
                Button(action: onOpenExpenses) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard.fill")
                        Text("Manage")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeManager.currentPalette.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            Text("Track trip expenses alongside your packing list.")
                .font(.caption)
                .foregroundColor(themeManager.currentPalette.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentPalette.background)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

private struct PackingProgressCardView: View {
    let packedCount: Int
    let totalCount: Int
    let totalWeight: Double
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Packing Progress")
                        .font(.headline)
                        .foregroundColor(themeManager.currentPalette.text)
                    Text(String(format: "%d of %d items packed", packedCount, totalCount))
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentPalette.secondaryText)
                    if totalWeight > 0 {
                        Text(String(format: "Total Weight: %.1f kg", totalWeight))
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                    }
                }
                Spacer()
                CircularProgressView(progress: Double(packedCount) / Double(max(totalCount, 1)))
                    .frame(width: 70, height: 70)
            }

            ProgressView(value: Double(min(packedCount, totalCount)), total: Double(max(totalCount, 1)))
                .tint(themeManager.currentPalette.accent)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [themeManager.currentPalette.accent.opacity(0.15), themeManager.currentPalette.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.currentPalette.accent.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

private struct PackingActionButtonsView: View {
    @Binding var showingSuggestions: Bool
    @Binding var showingAddItem: Bool
    @Binding var showingTemplates: Bool
    @Binding var showingDuplicateFrom: Bool
    @Binding var showingExport: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: { showingSuggestions = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.headline)
                        Text("Smart Suggestions")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
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
                
                Button(action: { showingAddItem = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Add Item")
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { showingTemplates = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.subheadline)
                        Text("Templates")
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(themeManager.currentPalette.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.currentPalette.background)
                    .cornerRadius(10)
                    .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.currentPalette.accent.opacity(0.1), lineWidth: 1)
                    )
                }
                
                Button(action: { showingDuplicateFrom = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                        Text("Copy from Trip")
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(themeManager.currentPalette.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.currentPalette.background)
                    .cornerRadius(10)
                    .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.currentPalette.accent.opacity(0.1), lineWidth: 1)
                    )
                }
                
                Button(action: { showingExport = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.subheadline)
                        Text("Share")
                            .font(.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(themeManager.currentPalette.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.currentPalette.background)
                    .cornerRadius(10)
                    .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.currentPalette.accent.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct PackingViewModePickerView: View {
    @Binding var viewMode: PackingListView.ViewMode
    
    var body: some View {
        Picker("View Mode", selection: $viewMode) {
            ForEach(PackingListView.ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

private struct PackingFilterSectionView: View {
    let viewMode: PackingListView.ViewMode
    @Binding var selectedCategory: String?
    @Binding var selectedBag: String?
    let itemsByCategory: [String: [PackingItem]]
    let uniqueBags: [String]
    
    var body: some View {
        Group {
            if viewMode == .category && !itemsByCategory.isEmpty {
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
            } else if viewMode == .bag && !uniqueBags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(title: "All Bags", isSelected: selectedBag == nil) {
                            selectedBag = nil
                        }
                        ForEach(uniqueBags, id: \.self) { bag in
                            CategoryChip(title: bag, isSelected: selectedBag == bag) {
                                selectedBag = bag
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

private struct PackingItemsSectionView: View {
    let packingItems: [PackingItem]
    let viewMode: PackingListView.ViewMode
    let selectedCategory: String?
    let selectedBag: String?
    let itemsByCategory: [String: [PackingItem]]
    let itemsByBag: [String: [PackingItem]]
    let trip: TripModel
    let modelContext: ModelContext
    
    var body: some View {
        Group {
            if packingItems.isEmpty {
                EmptyPackingListView()
            } else {
                PackingItemsListView(
                    packingItems: packingItems,
                    viewMode: viewMode,
                    selectedCategory: selectedCategory,
                    selectedBag: selectedBag,
                    itemsByCategory: itemsByCategory,
                    itemsByBag: itemsByBag,
                    trip: trip,
                    modelContext: modelContext
                )
            }
        }
    }
}

private struct EmptyPackingListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(themeManager.currentPalette.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 36))
                    .foregroundColor(themeManager.currentPalette.accent)
            }
            
            VStack(spacing: 6) {
                Text("Pack like a pro")
                    .font(.headline)
                    .foregroundColor(themeManager.currentPalette.text)
                
                Text("Don't forget the essentials. Add items manually or use AI to generate a smart packing list.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.currentPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct PackingItemsListView: View {
    let packingItems: [PackingItem]
    let viewMode: PackingListView.ViewMode
    let selectedCategory: String?
    let selectedBag: String?
    let itemsByCategory: [String: [PackingItem]]
    let itemsByBag: [String: [PackingItem]]
    let trip: TripModel
    let modelContext: ModelContext
    
    var filteredItems: [PackingItem] {
        switch viewMode {
        case .category:
            return selectedCategory == nil ?
                packingItems :
                packingItems.filter { $0.category == selectedCategory }
        case .bag:
            return selectedBag == nil ?
                packingItems :
                packingItems.filter { $0.bagName == selectedBag }
        case .essential:
            return packingItems
        }
    }
    
    var body: some View {
        Group {
            if viewMode == .category || viewMode == .essential {
                ForEach(filteredItems) { item in
                    EnhancedPackingItemRowView(item: item, trip: trip, modelContext: modelContext)
                        .padding(.horizontal)
                }
            } else {
                ForEach(Array(itemsByBag.keys.sorted()), id: \.self) { bagName in
                    if selectedBag == nil || selectedBag == bagName {
                        BagGroupView(
                            bagName: bagName,
                            bagItems: itemsByBag[bagName] ?? [],
                            trip: trip,
                            modelContext: modelContext
                        )
                    }
                }
            }
        }
    }
}

private struct BagGroupView: View {
    let bagName: String
    let bagItems: [PackingItem]
    let trip: TripModel
    let modelContext: ModelContext
    
    var bagWeight: Double {
        bagItems.compactMap { item in
            item.estimatedWeight.map { $0 * Double(item.quantity) }
        }.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(.blue)
                Text(bagName)
                    .font(.headline)
                Spacer()
                if bagWeight > 0 {
                    Text(String(format: "%.1f kg", bagWeight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            ForEach(bagItems.sorted(by: { $0.order < $1.order })) { item in
                EnhancedPackingItemRowView(item: item, trip: trip, modelContext: modelContext)
                    .padding(.horizontal)
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Circle()
                .stroke(themeManager.currentPalette.accent.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(themeManager.currentPalette.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            let percentage = max(0, min(100, Int((progress * 100).rounded())))
            Text("\(percentage)%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentPalette.text)
        }
    }
}

struct EnhancedPackingItemRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Bindable var item: PackingItem
    let trip: TripModel
    let modelContext: ModelContext
    @State private var showingEdit = false
    @State private var showingDetails = false
    
    var body: some View {
        Button(role: .none) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                let wasPacked = item.isPacked
                item.isPacked.toggle()
                trip.lastModified = Date()
                try? modelContext.save()
                
                if !wasPacked && item.isPacked {
                    HapticManager.shared.success()
                } else {
                    HapticManager.shared.selection()
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(item.isPacked ? .green : .secondary)
                        .scaleEffect(item.isPacked ? 1.1 : 1.0)
                        
                    if item.isPacked {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .scaleEffect(item.isPacked ? 1.3 : 1.0)
                            .opacity(item.isPacked ? 0 : 1)
                            .animation(.easeOut(duration: 0.4), value: item.isPacked)
                    }
                }
                
                // Photo thumbnail
                if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeManager.currentPalette.accent.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: item.category.lowercased().contains("cloth") ? "tshirt.fill" :
                                  item.category.lowercased().contains("electron") ? "iphone" :
                                  item.category.lowercased().contains("health") ? "cross.case.fill" :
                                  "suitcase.fill")
                                .foregroundColor(themeManager.currentPalette.accent)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .strikethrough(item.isPacked)
                            .foregroundColor(item.isPacked ? themeManager.currentPalette.secondaryText : themeManager.currentPalette.text)
                        
                        if item.isEssential {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(item.category)
                            .font(.caption)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                        
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentPalette.secondaryText)
                        }
                        
                        if let weight = item.estimatedWeight {
                            Text(String(format: "%.1f kg", weight * Double(item.quantity)))
                                .font(.caption)
                                .foregroundColor(themeManager.currentPalette.secondaryText)
                        }
                        
                        if let bag = item.bagName, !bag.isEmpty {
                            Label(bag, systemImage: "bag.fill")
                                .font(.caption)
                                .foregroundColor(themeManager.currentPalette.accent)
                        }
                    }
                    
                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentPalette.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: { showingEdit = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(action: { showingDetails = true }) {
                        Label("Details", systemImage: "info.circle")
                    }
                    Divider()
                    Button(role: .destructive, action: {
                        trip.packingList?.removeAll { $0.id == item.id }
                        trip.lastModified = Date()
                        try? modelContext.save()
                        HapticManager.shared.error()
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
            .padding()
            .background(
                item.isPacked ?
                Color.green.opacity(0.08) :
                (item.isEssential ? themeManager.currentPalette.accent.opacity(0.12) : themeManager.currentPalette.background)
            )
            .cornerRadius(16)
            .shadow(color: themeManager.currentPalette.accent.opacity(0.04), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEdit) {
            EditPackingItemView(item: item)
        }
        .sheet(isPresented: $showingDetails) {
            PackingItemDetailView(item: item)
        }
    }
}


// MARK: - Packing Suggestions View
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
                    Text("Get personalized packing suggestions based on your trip destination, duration, and weather forecast.")
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
    @EnvironmentObject var themeManager: ThemeManager
    
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
                    .background(themeManager.currentPalette.background)
                    .cornerRadius(12)
                    .shadow(color: themeManager.currentPalette.accent.opacity(0.06), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.currentPalette.accent.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }
    
    private func addItem(from suggestion: PackingSuggestion) {
        let existingItems = trip.packingList ?? []

        // Check Pro limit - silently return if limit reached
        let limitCheck = ProLimiter.shared.canAddPackingItem(currentItemCount: existingItems.count)
        guard limitCheck.allowed else { return }

        if !existingItems.contains(where: { $0.name == suggestion.item }) {
            let newItem = PackingItem(
                name: suggestion.item,
                isPacked: false,
                category: suggestion.category,
                order: existingItems.count,
                isEssential: suggestion.priority == .essential
            )
            modelContext.insert(newItem)

            if trip.packingList == nil {
                trip.packingList = []
            }
            trip.packingList?.append(newItem)
            trip.lastModified = Date()

            try? modelContext.save()
            HapticManager.shared.success()
        }
    }
}

// MARK: - Add Packing Item View
struct AddPackingItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    @State private var name: String = ""
    @State private var category: String = "General"
    @State private var quantity: Int = 1
    @State private var estimatedWeight: String = ""
    @State private var notes: String = ""
    @State private var bagName: String = ""
    @State private var isPacked: Bool = false
    @State private var isEssential: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var limitMessage: String?
    
    private let categories = ["Clothing", "Electronics", "Toiletries", "Documents", "Health", "Accessories", "Footwear", "Essentials", "General"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                name = oldValue
                            }
                        }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Estimated Weight (kg)", text: $estimatedWeight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Bag/Luggage Name (optional)", text: $bagName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: bagName) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                bagName = oldValue
                            }
                        }
                }
                
                Section("Additional Info") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: notes) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                notes = oldValue
                            }
                        }
                    
                    Toggle("Mark as Essential", isOn: $isEssential)
                    
                    Toggle("Mark as Packed", isOn: $isPacked)
                }
                
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                                Text("Change Photo")
                            } else {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Add Photo")
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    
                    if photoData != nil {
                        Button(role: .destructive, action: {
                            photoData = nil
                            selectedPhoto = nil
                        }) {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Add Packing Item")
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

                        // Check Pro limit
                        let limitCheck = ProLimiter.shared.canAddPackingItem(currentItemCount: existingItems.count)
                        if !limitCheck.allowed {
                            // Show alert and return without dismissing
                            limitMessage = limitCheck.reason
                            return
                        }

                        let weight = Double(estimatedWeight) ?? nil
                        let newItem = PackingItem(
                            name: name,
                            isPacked: isPacked,
                            category: category,
                            order: existingItems.count,
                            quantity: quantity,
                            estimatedWeight: weight,
                            notes: notes,
                            photoData: photoData,
                            bagName: bagName.isEmpty ? nil : bagName,
                            isEssential: isEssential
                        )
                        modelContext.insert(newItem)

                        if trip.packingList == nil {
                            trip.packingList = []
                        }
                        trip.packingList?.append(newItem)
                        trip.lastModified = Date()

                        do {
                            try modelContext.save()
                            HapticManager.shared.success()
                        } catch {
                            #if DEBUG
                            print("Failed to save packing item: \(error)")
                            #endif
                            HapticManager.shared.error()
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .alert("Limit Reached", isPresented: Binding(
            get: { limitMessage != nil },
            set: { if !$0 { limitMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(limitMessage ?? "")
        }
    }
}

// MARK: - Edit Packing Item View
struct EditPackingItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: PackingItem
    
    @State private var name: String
    @State private var category: String
    @State private var quantity: Int
    @State private var estimatedWeight: String
    @State private var notes: String
    @State private var bagName: String
    @State private var isPacked: Bool
    @State private var isEssential: Bool
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data?
    
    private let categories = ["Clothing", "Electronics", "Toiletries", "Documents", "Health", "Accessories", "Footwear", "Essentials", "General"]
    
    init(item: PackingItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _quantity = State(initialValue: item.quantity)
        _estimatedWeight = State(initialValue: item.estimatedWeight.map { String(format: "%.1f", $0) } ?? "")
        _notes = State(initialValue: item.notes)
        _bagName = State(initialValue: item.bagName ?? "")
        _isPacked = State(initialValue: item.isPacked)
        _isEssential = State(initialValue: item.isEssential)
        _photoData = State(initialValue: item.photoData)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                name = oldValue
                            }
                        }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Estimated Weight (kg)", text: $estimatedWeight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Bag/Luggage Name (optional)", text: $bagName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: bagName) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                bagName = oldValue
                            }
                        }
                }
                
                Section("Additional Info") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: notes) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                notes = oldValue
                            }
                        }
                    
                    Toggle("Mark as Essential", isOn: $isEssential)
                    
                    Toggle("Packed", isOn: $isPacked)
                }
                
                Section("Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .clipped()
                                Text("Change Photo")
                            } else {
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Add Photo")
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                photoData = data
                            }
                        }
                    }
                    
                    if photoData != nil {
                        Button(role: .destructive, action: {
                            photoData = nil
                            selectedPhoto = nil
                        }) {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Edit Packing Item")
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
                        item.quantity = quantity
                        item.estimatedWeight = Double(estimatedWeight)
                        item.notes = notes
                        item.bagName = bagName.isEmpty ? nil : bagName
                        item.isPacked = isPacked
                        item.isEssential = isEssential
                        item.photoData = photoData
                        
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

// MARK: - Packing Item Detail View
struct PackingItemDetailView: View {
    @Environment(\.dismiss) var dismiss
    let item: PackingItem
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let photoData = item.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                            .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(item.name)
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                            .fontWeight(.bold)
                        
                        HStack {
                            Label(item.category, systemImage: "tag.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if item.isEssential {
                                Label("Essential", systemImage: "star.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Divider()
                        
                        if item.quantity > 1 {
                            DetailRow(label: "Quantity", value: "\(item.quantity)")
                        }
                        
                        if let weight = item.estimatedWeight {
                            DetailRow(label: "Weight", value: String(format: "%.1f kg", weight * Double(item.quantity)))
                        }
                        
                        if let bag = item.bagName, !bag.isEmpty {
                            DetailRow(label: "Bag", value: bag, icon: "bag.fill")
                        }
                        
                        if !item.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.headline)
                                Text(item.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Item Details")
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

struct DetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
            }
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Packing Templates View
struct PackingTemplatesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    
    let templates: [PackingTemplate] = [
        PackingTemplate(
            name: "Beach Vacation",
            items: [
                ("Swimsuit", "Clothing", 2),
                ("Beach Towel", "Accessories", 1),
                ("Sunscreen SPF 50+", "Health", 1),
                ("Sunglasses", "Accessories", 1),
                ("Flip Flops", "Footwear", 1),
                ("Beach Bag", "Accessories", 1),
                ("Hat", "Accessories", 1),
                ("Cover-up", "Clothing", 2)
            ]
        ),
        PackingTemplate(
            name: "Business Trip",
            items: [
                ("Business Suit", "Clothing", 1),
                ("Dress Shirts", "Clothing", 3),
                ("Dress Shoes", "Footwear", 1),
                ("Laptop", "Electronics", 1),
                ("Notebook", "Essentials", 1),
                ("Business Cards", "Essentials", 1),
                ("Travel Adapter", "Electronics", 1)
            ]
        ),
        PackingTemplate(
            name: "Adventure/Outdoor",
            items: [
                ("Hiking Boots", "Footwear", 1),
                ("Backpack", "Accessories", 1),
                ("Water Bottle", "Essentials", 1),
                ("First Aid Kit", "Health", 1),
                ("Compass", "Essentials", 1),
                ("Multi-tool", "Essentials", 1),
                ("Headlamp", "Electronics", 1),
                ("Rain Jacket", "Clothing", 1)
            ]
        ),
        PackingTemplate(
            name: "City Break",
            items: [
                ("Comfortable Walking Shoes", "Footwear", 1),
                ("City Map/Guide", "Essentials", 1),
                ("Camera", "Electronics", 1),
                ("Portable Charger", "Electronics", 1),
                ("Day Bag", "Accessories", 1),
                ("Umbrella", "Accessories", 1)
            ]
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    Button(action: {
                        applyTemplate(template)
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.name)
                                .font(.headline)
                            Text("\(template.items.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Packing Templates")
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
    
    private func applyTemplate(_ template: PackingTemplate) {
        let existingItems = trip.packingList ?? []
        var order = existingItems.count
        
        for (name, category, quantity) in template.items {
            if !(existingItems.contains { $0.name == name }) {
                let newItem = PackingItem(
                    name: name,
                    isPacked: false,
                    category: category,
                    order: order,
                    quantity: quantity
                )
                modelContext.insert(newItem)
                
                if trip.packingList == nil {
                    trip.packingList = []
                }
                trip.packingList?.append(newItem)
                order += 1
            }
        }
        
        trip.lastModified = Date()
        try? modelContext.save()
        HapticManager.shared.success()
        dismiss()
    }
}

struct PackingTemplate: Identifiable {
    let id = UUID()
    let name: String
    let items: [(String, String, Int)] // (name, category, quantity)
}

// MARK: - Duplicate Packing List View
struct DuplicatePackingListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: TripModel
    let allTrips: [TripModel]
    
    var body: some View {
        NavigationStack {
            List {
                if allTrips.isEmpty {
                    Text("No other trips to copy from")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(allTrips) { otherTrip in
                        Button(action: {
                            duplicateItems(from: otherTrip)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(otherTrip.name)
                                    .font(.headline)
                                if let items = otherTrip.packingList, !items.isEmpty {
                                    Text("\(items.count) items")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Copy from Trip")
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
    
    private func duplicateItems(from sourceTrip: TripModel) {
        guard let sourceItems = sourceTrip.packingList else { return }
        let existingItems = trip.packingList ?? []
        var order = existingItems.count
        
        for sourceItem in sourceItems {
            if !(existingItems.contains { $0.name == sourceItem.name }) {
                let newItem = PackingItem(
                    name: sourceItem.name,
                    isPacked: false,
                    category: sourceItem.category,
                    order: order,
                    quantity: sourceItem.quantity,
                    estimatedWeight: sourceItem.estimatedWeight,
                    notes: sourceItem.notes,
                    photoData: sourceItem.photoData,
                    bagName: sourceItem.bagName,
                    isEssential: sourceItem.isEssential
                )
                modelContext.insert(newItem)
                
                if trip.packingList == nil {
                    trip.packingList = []
                }
                trip.packingList?.append(newItem)
                order += 1
            }
        }
        
        trip.lastModified = Date()
        try? modelContext.save()
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Share Packing List View
struct SharePackingListView: View {
    @Environment(\.dismiss) var dismiss
    let trip: TripModel
    let items: [PackingItem]
    @State private var shareText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $shareText)
                        .onChange(of: shareText) { oldValue, newValue in
                            if ContentFilter.containsBlockedContent(newValue) {
                                shareText = oldValue
                            }
                        }
                        .frame(height: 300)
                } header: {
                    Text("Packing List")
                } footer: {
                    Text("Copy this list or share it with others")
                }
            }
            .navigationTitle("Share Packing List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: shareText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                generateShareText()
            }
        }
    }
    
    private func generateShareText() {
        var text = "\(trip.name) - Packing List\n"
        text += "\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) - \(trip.endDate.formatted(date: .abbreviated, time: .omitted))\n\n"
        
        let itemsByCategory: [String: [PackingItem]] = Dictionary(grouping: items) { (item: PackingItem) in
            item.category
        }
        
        for category in itemsByCategory.keys.sorted() {
            text += "\(category):\n"
            for item in itemsByCategory[category] ?? [] {
                let checkmark = item.isPacked ? "✓" : "☐"
                let quantity = item.quantity > 1 ? " ×\(item.quantity)" : ""
                text += "  \(checkmark) \(item.name)\(quantity)\n"
            }
            text += "\n"
        }
        
        if totalWeight > 0 {
            text += "\nTotal Weight: \(String(format: "%.1f kg", totalWeight))"
        }
        
        shareText = text
    }
    
    private var totalWeight: Double {
        items.compactMap { item in
            item.estimatedWeight.map { $0 * Double(item.quantity) }
        }.reduce(0, +)
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

