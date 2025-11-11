//
//  TripExportView.swift
//  Triply
//
//  Created on 2024
//

import SwiftUI

struct TripExportView: View {
    @Environment(\.dismiss) var dismiss
    let trip: TripModel
    @StateObject private var exportManager = ExportManager.shared
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button(action: {
                        shareItems = exportManager.shareTrip(trip: trip)
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Trip Details")
                        }
                    }
                    
                    Button(action: {
                        let pdfText = exportManager.exportTripToPDF(trip: trip)
                        shareItems = [pdfText]
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Export as Text")
                        }
                    }
                    
                    Button(action: {
                        let csvText = exportManager.exportTripToCSV(trip: trip)
                        shareItems = [csvText]
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "tablecells")
                            Text("Export as CSV")
                        }
                    }
                } header: {
                    Text("Export Options")
                } footer: {
                    Text("Export your trip details in various formats for sharing or backup.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                        Text(exportManager.exportTripToPDF(trip: trip))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Export Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                TripShareSheet(items: shareItems)
            }
        }
    }
}

struct TripShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

