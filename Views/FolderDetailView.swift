//
//  FolderDetailView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct FolderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let folder: DocumentFolder
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var selectedDocument: TripDocument?
    
    var folderDocuments: [TripDocument] {
        folder.documents?.sorted(by: { $0.createdAt > $1.createdAt }) ?? []
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Folder Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: folder.color)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: folder.icon)
                                .font(.system(size: 40))
                                .foregroundColor(Color(hex: folder.color) ?? .blue)
                        }
                        
                        Text(folder.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(folderDocuments.count) document\(folderDocuments.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Documents List
                    if folderDocuments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No Documents")
                                .font(.headline)
                            Text("Add documents to this folder to organize them")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 60)
                    } else {
                        ForEach(folderDocuments) { document in
                            DocumentCard(document: document)
                                .onTapGesture {
                                    selectedDocument = document
                                }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditSheet) {
                EditFolderView(folder: folder)
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(document: document)
            }
            .alert("Delete Folder", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteFolder()
                }
            } message: {
                Text("Are you sure you want to delete this folder? Documents in this folder will be moved to the main documents list.")
            }
        }
    }
    
    private func deleteFolder() {
        // Move documents out of folder before deleting
        if let documents = folder.documents {
            for document in documents {
                document.folder = nil
            }
        }
        
        modelContext.delete(folder)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete folder: \(error)")
        }
    }
}

struct EditFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var iapManager = IAPManager.shared
    
    let folder: DocumentFolder
    
    @State private var folderName: String
    @State private var selectedColor: String
    @State private var selectedColorPicker: Color
    @State private var selectedIcon: String
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
    
    // Computed property for current color to use in UI
    private var currentColor: Color {
        selectedColorPicker
    }
    
    init(folder: DocumentFolder) {
        self.folder = folder
        _folderName = State(initialValue: folder.name)
        _selectedColor = State(initialValue: folder.color)
        _selectedColorPicker = State(initialValue: Color(hex: folder.color) ?? .blue)
        _selectedIcon = State(initialValue: folder.icon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Folder Name", text: $folderName)
                        .textInputAutocapitalization(.words)
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
                                Text("Selected Color:")
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
                                    Text("Upgrade to Pro for unlimited colors & custom color picker")
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
                    Text("Folder Color")
                } footer: {
                    if !iapManager.isPro {
                        Text("Free: 3 colors • Pro: Unlimited colors with color picker")
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
                                            .fill(selectedColorPicker.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                        
                                        Image(systemName: icon)
                                            .font(.title2)
                                            .foregroundColor(selectedColorPicker)
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIcon == icon ? selectedColorPicker : Color.clear, lineWidth: 2)
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
                                Text("Upgrade to Pro for \(proIcons.count - basicIcons.count) more icons")
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
                        Text("Folder Icon")
                        Spacer()
                        if iapManager.isPro {
                            Text("\(folderIcons.count) icons")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } footer: {
                    if !iapManager.isPro {
                        Text("Free: \(basicIcons.count) icons • Pro: \(proIcons.count) icons")
                    } else {
                        Text("\(proIcons.count) icons available")
                    }
                }
            }
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFolder()
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    PaywallView()
                }
            }
        }
    }
    
    private func saveFolder() {
        folder.name = folderName.trimmingCharacters(in: .whitespaces)
        folder.color = selectedColor
        folder.icon = selectedIcon
        folder.updatedAt = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save folder: \(error)")
        }
    }
}

