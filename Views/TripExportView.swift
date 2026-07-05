//
//  TripExportView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import UniformTypeIdentifiers

/// Provides PDF data to the share sheet on demand, avoiding "error fetching item for URL" when sharing from tmp/caches.
final class PDFShareItemProvider: NSObject, UIActivityItemSource {
    private let data: Data
    private let fileName: String
    
    init(pdfData: Data, fileName: String = "Trip.pdf") {
        self.data = pdfData
        self.fileName = fileName
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        UTType.pdf.identifier
    }
}

struct TripExportView: View {
    @Environment(\.dismiss) var dismiss
    let trip: TripModel
    @StateObject private var exportManager = ExportManager.shared
    @StateObject private var proLimiter = ProLimiter.shared
    @State private var showingShareSheet = false
    @State private var showingPaywall = false
    @State private var showingAddToCalendar = false
    @State private var shareItems: [Any] = []
    
    private var canExport: Bool { proLimiter.canAccessAdvancedExport().allowed }
    
    var body: some View {
        NavigationStack {
            if canExport {
                exportForm
            } else {
                advancedExportPaywallPrompt
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            TripShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack { PaywallView() }
        }
        .sheet(isPresented: $showingAddToCalendar) {
            TripCalendarView(trip: trip)
        }
    }
    
    private var exportForm: some View {
        Form {
            Section {
                Button(action: {
                    shareItems = exportManager.shareTrip(trip: trip)
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("export.shareTripDetails".localized)
                    }
                }
                
                Button(action: {
                    if let pdfData = exportManager.exportTripToPDFData(trip: trip) {
                        let safeName = trip.name
                            .replacingOccurrences(of: "/", with: "-")
                            .replacingOccurrences(of: " ", with: "-")
                            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
                        let fileName = (safeName.isEmpty ? "Itinero-Trip" : safeName) + ".pdf"
                        shareItems = [PDFShareItemProvider(pdfData: pdfData, fileName: fileName)]
                    } else {
                        shareItems = [exportManager.exportTripToPDF(trip: trip)]
                    }
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("export.asPdf".localized)
                    }
                }
                
                Button(action: {
                    let pdfText = exportManager.exportTripToPDF(trip: trip)
                    shareItems = [pdfText]
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("export.asText".localized)
                    }
                }
                
                Button(action: {
                    let csvText = exportManager.exportTripToCSV(trip: trip)
                    shareItems = [csvText]
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "tablecells")
                        Text("export.asCsv".localized)
                    }
                }
                
                Button(action: { showingAddToCalendar = true }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("export.toAppleCalendar".localized)
                    }
                }
            } header: {
                Text("export.options".localized)
            } footer: {
                Text("export.optionsDescription".localized)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("settings.preview".localized)
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
        .navigationTitle("export.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.done".localized) { dismiss() }
            }
        }
    }
    
    private var advancedExportPaywallPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("export.advancedPro".localized)
                .font(.title2.bold())
            Text("export.upgradeToUnlock".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: { showingPaywall = true }) {
                Text("pro.upgrade".localized)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.top, 48)
        .navigationTitle("export.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("common.done".localized) { dismiss() }
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

