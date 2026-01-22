//
//  CreateFolderView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var iapManager = IAPManager.shared
    
    let trip: TripModel
    
    @State private var folderName = ""
    @State private var selectedColor = "#007AFF"
    @State private var selectedColorPicker: Color = .blue
    @State private var selectedIcon = "folder.fill"
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showPaywall = false
    
    // Free tier: 3 colors, Pro: unlimited
    private let freeTierColors = [
        "#007AFF", "#34C759", "#FF9500"
    ]
    
    // Extended icon set for pro users
    private let basicIcons = [
        "folder.fill", "ticket.fill", "person.2.fill", "airplane", "car.fill", "bed.double.fill",
        "calendar", "doc.fill", "creditcard.fill", "map.fill", "camera.fill", "heart.fill"
    ]
    
    private let proIcons = [
        "folder.fill", "ticket.fill", "person.2.fill", "person.3.fill", "airplane", "airplane.departure",
        "car.fill", "car.2.fill", "bed.double.fill", "house.fill", "building.2.fill", "calendar",
        "calendar.badge.clock", "doc.fill", "doc.text.fill", "creditcard.fill", "map.fill", "map.circle.fill",
        "camera.fill", "camera.on.rectangle", "heart.fill", "heart.circle.fill", "star.fill", "star.circle.fill",
        "briefcase.fill", "briefcase.cross.fill", "graduationcap.fill", "figure.child", "figure.walk",
        "figure.run", "beach.umbrella.fill", "sun.max.fill", "moon.fill", "cloud.fill", "snowflake",
        "gamecontroller.fill", "music.note", "tv.fill", "book.fill", "bookmark.fill", "tag.fill",
        "bell.fill", "bell.badge.fill", "envelope.fill", "phone.fill", "message.fill", "bubble.left.fill",
        "paintbrush.fill", "paintpalette.fill", "wand.and.stars", "sparkles", "bolt.fill", "flame.fill",
        "drop.fill", "leaf.fill", "tree.fill", "mountain.2.fill", "water.waves", "sailboat.fill",
        "ferry.fill", "tram.fill", "bicycle", "figure.stand", "figure.arms.open", "figure.dance"
    ]
    
    var folderIcons: [String] {
        iapManager.isPro ? proIcons : basicIcons
    }
    
    // Preset folder templates for different group types
    private let folderPresets: [FolderPreset] = [
        FolderPreset(name: "Family", icon: "person.2.fill", color: "#FF9500", description: "Family members"),
        FolderPreset(name: "Couple", icon: "heart.fill", color: "#FF2D55", description: "Couple's travel"),
        FolderPreset(name: "Friends", icon: "person.3.fill", color: "#34C759", description: "Friends group"),
        FolderPreset(name: "Colleagues", icon: "briefcase.fill", color: "#007AFF", description: "Business travel"),
        FolderPreset(name: "Solo", icon: "person.fill", color: "#AF52DE", description: "Personal"),
        FolderPreset(name: "Group", icon: "person.2.circle.fill", color: "#FF3B30", description: "Large group"),
        FolderPreset(name: "Children", icon: "figure.child", color: "#5856D6", description: "Kids' documents"),
        FolderPreset(name: "Students", icon: "graduationcap.fill", color: "#00C7BE", description: "Student group"),
        FolderPreset(name: "Custom", icon: "folder.fill", color: "#007AFF", description: "Custom folder")
    ]
    
    var isFormValid: Bool {
        !folderName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // Computed property for current color to use in UI
    private var currentColor: Color {
        selectedColorPicker
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Quick Presets Section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(folderPresets) { preset in
                                Button {
                                    folderName = preset.name
                                    selectedColor = preset.color
                                    selectedColorPicker = Color(hex: preset.color) ?? .blue
                                    selectedIcon = preset.icon
                                } label: {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(hex: preset.color)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: preset.icon)
                                                .font(.title2)
                                                .foregroundColor(Color(hex: preset.color) ?? .blue)
                                        }
                                        
                                        Text(preset.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text(preset.description)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(folderName == preset.name ? Color(hex: preset.color)?.opacity(0.1) ?? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(folderName == preset.name ? Color(hex: preset.color) ?? .blue : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Quick Presets")
                } footer: {
                    Text("Choose a preset or create custom")
                }
                
                Section("Folder Name") {
                    TextField("", text: $folderName)
                        .foregroundColor(.primary)
                        .textInputAutocapitalization(.words)
                    
                    if folderName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("Folder name is required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Section {
                    // Free tier: limited colors, Pro: color picker
                    if iapManager.isPro {
                        // Pro: Color Picker
                        VStack(alignment: .leading, spacing: 12) {
                            ColorPicker("Select Folder Color", selection: $selectedColorPicker, supportsOpacity: false)
                                .onChange(of: selectedColorPicker) { oldValue, newValue in
                                    // Convert Color to hex immediately when changed
                                    selectedColor = newValue.hexRGBA
                                }
                            
                            // Show current selected color preview
                            HStack {
                                Text("Selected Color")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Circle()
                                    .fill(selectedColorPicker)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                                    )
                                    .shadow(color: selectedColorPicker.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                    } else {
                        // Free tier: 3 colors only
                        VStack(alignment: .leading, spacing: 12) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                                ForEach(freeTierColors, id: \.self) { colorHex in
                                    Button {
                                        selectedColor = colorHex
                                        selectedColorPicker = Color(hex: colorHex) ?? .blue
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: colorHex) ?? .blue)
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == colorHex ? Color.primary : Color.clear, lineWidth: 3)
                                            )
                                            .overlay(
                                                Image(systemName: selectedColor == colorHex ? "checkmark" : "")
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            
                            // Upgrade prompt
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    Text("Upgrade to Pro")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                } header: {
                    Text("Color")
                } footer: {
                    if !iapManager.isPro {
                        Text("Free Colors")
                    }
                }
                
                Section {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                            ForEach(folderIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(currentColor.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(currentColor)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIcon == icon ? currentColor : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: iapManager.isPro ? 400 : 200)
                    
                    if !iapManager.isPro {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "Upgrade to Pro to unlock %d more icons", proIcons.count - basicIcons.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                } header: {
                    HStack {
                        Text("Icon")
                        Spacer()
                        if iapManager.isPro {
                            Text(String(format: "%d icons available", folderIcons.count))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    if !iapManager.isPro {
                        Text(String(format: "%d free, %d pro", basicIcons.count, proIcons.count))
                    } else {
                        Text(String(format: "%d pro icons available", proIcons.count))
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    PaywallView()
                }
            }
            .onAppear {
                // Initialize color picker with selected color
                selectedColorPicker = Color(hex: selectedColor) ?? .blue
            }
        }
    }
    
    private func createFolder() {
        guard isFormValid else {
            errorMessage = "Please enter a folder name"
            showErrorAlert = true
            return
        }
        
        let folder = DocumentFolder(
            name: folderName.trimmingCharacters(in: .whitespaces),
            color: selectedColor,
            icon: selectedIcon,
            trip: trip
        )
        
        modelContext.insert(folder)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - Folder Preset Model
struct FolderPreset: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: String
    let description: String
}
