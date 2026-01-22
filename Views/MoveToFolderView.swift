//
//  MoveToFolderView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct MoveToFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DocumentFolder.createdAt, order: .forward) private var allFolders: [DocumentFolder]
    
    let document: TripDocument
    let trip: TripModel
    
    var tripFolders: [DocumentFolder] {
        allFolders.filter { folder in
            folder.trip?.id == trip.id
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Remove from folder option
                Section {
                    Button {
                        document.folder = nil
                        saveChanges()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.minus")
                                .foregroundColor(.secondary)
                            Text("Remove from Folder")
                                .foregroundColor(.primary)
                            Spacer()
                            if document.folder == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Current Location")
                }
                
                // Folders list
                if tripFolders.isEmpty {
                    Section {
                        Text("No folders available. Create a folder first.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                } else {
                    Section {
                        ForEach(tripFolders) { folder in
                            Button {
                                document.folder = folder
                                saveChanges()
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: folder.color)?.opacity(0.2) ?? Color.blue.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: folder.icon)
                                            .foregroundColor(Color(hex: folder.color) ?? .blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(folder.name)
                                            .foregroundColor(.primary)
                                            .font(.headline)
                                        Text("\(folder.documentCount) document\(folder.documentCount == 1 ? "" : "s")")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    if document.folder?.id == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Folders")
                    }
                }
            }
            .navigationTitle("Move to Folder")
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
    
    private func saveChanges() {
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to move document: \(error)")
        }
    }
}


