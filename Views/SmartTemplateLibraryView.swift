//
//  SmartTemplateLibraryView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct SmartTemplateLibraryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var templateManager = SmartTemplateManager.shared
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var showingTemplateDetail: SmartTripTemplate?
    @State private var showingPaywall = false
    
    let onTemplateSelected: (SmartTripTemplate) -> Void
    
    var categories: [String] {
        Array(Set(templateManager.templates.map { $0.category })).sorted()
    }
    
    var filteredTemplates: [SmartTripTemplate] {
        var templates = templateManager.templates
        
        if !searchText.isEmpty {
            templates = templateManager.searchTemplates(query: searchText)
        }
        
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        // Filter Pro templates if user is not Pro
        if !proLimiter.isPro {
            templates = templates.filter { !$0.isPro }
        }
        
        return templates.sorted { $0.popularity > $1.popularity }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search templates...", text: $searchText)
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
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TemplateCategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            TemplateCategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Templates Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateLibraryCard(template: template) {
                                if template.isPro && !proLimiter.isPro {
                                    showingPaywall = true
                                } else {
                                    showingTemplateDetail = template
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trip Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $showingTemplateDetail) { template in
                TemplateDetailView(template: template, onApply: { appliedTemplate in
                    onTemplateSelected(appliedTemplate)
                    dismiss()
                })
            }
            .sheet(isPresented: $showingPaywall) {
                NavigationStack {
                    PaywallView()
                }
            }
        }
    }
}

struct TemplateLibraryCard: View {
    let template: SmartTripTemplate
    let action: () -> Void
    
    private var templateColor: Color {
        Color(hex: template.colorHex) ?? .blue
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(templateColor.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: template.icon)
                            .foregroundColor(templateColor)
                            .font(.title3)
                    }
                    
                    Spacer()
                    
                    if template.isPro {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(template.destination)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("\(template.suggestedDuration) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                if !template.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(template.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(templateColor.opacity(0.1))
                                    .foregroundColor(templateColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(templateColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TemplateDetailView: View {
    let template: SmartTripTemplate
    let onApply: (SmartTripTemplate) -> Void
    @Environment(\.dismiss) var dismiss
    
    private var templateColor: Color {
        Color(hex: template.colorHex) ?? .blue
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(templateColor.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: template.icon)
                                    .foregroundColor(templateColor)
                                    .font(.system(size: 40))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.title2.bold())
                                
                                Text(template.destination)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(template.details)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Suggested Destinations
                    if !template.suggestedDestinations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Destinations")
                                .font(.headline)
                            
                            ForEach(template.suggestedDestinations, id: \.self) { destination in
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(templateColor)
                                    Text(destination)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Suggested Itinerary
                    if !template.suggestedItinerary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Itinerary")
                                .font(.headline)
                            
                            ForEach(Array(template.suggestedItinerary.enumerated()), id: \.offset) { index, activity in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(templateColor)
                                        .clipShape(Circle())
                                    
                                    Text(activity)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Suggested Packing
                    if !template.suggestedPackingItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Packing List")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(template.suggestedPackingItems, id: \.self) { item in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(templateColor)
                                            .font(.caption)
                                        Text(item)
                                            .font(.caption)
                                    }
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Budget Info
                    if let budget = template.suggestedBudget {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Budget")
                                .font(.headline)
                            
                            Text("$\(Int(budget))")
                                .font(.title.bold())
                                .foregroundColor(templateColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
            .navigationTitle("Template Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply Template") {
                        onApply(template)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct TemplateCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

#Preview {
    SmartTemplateLibraryView { template in
        print("Selected: \(template.name)")
    }
}







