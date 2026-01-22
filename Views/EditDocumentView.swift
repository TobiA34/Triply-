//
//  EditDocumentView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct EditDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ticketScanner = TicketScannerManager()
    @StateObject private var settingsManager = SettingsManager.shared
    
    let document: TripDocument
    let trip: TripModel
    
    @State private var documentType: String
    @State private var title: String
    @State private var notes: String
    @State private var amountText: String
    @State private var date: Date?
    @State private var isSaving = false
    @State private var loadedImage: UIImage?
    @State private var hasScanned = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(document: TripDocument, trip: TripModel) {
        self.document = document
        self.trip = trip
        _documentType = State(initialValue: document.type)
        _title = State(initialValue: document.title)
        _notes = State(initialValue: document.notes)
        _amountText = State(initialValue: document.amount != nil ? String(format: "%.2f", document.amount!) : "")
        _date = State(initialValue: document.date ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Image Preview") {
                    if let image = loadedImage {
                        ZStack(alignment: .top) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 250)
                                .cornerRadius(8)
                                .overlay(
                                    ScanningOverlay(isScanning: $ticketScanner.isProcessing)
                                )
                            
                            if ticketScanner.isProcessing {
                                VStack {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 8) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.2)
                                            Text("Scanning...")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.black.opacity(0.7))
                                                .cornerRadius(8)
                                        }
                                        .padding()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                        
                        if !hasScanned && document.type == "ticket" {
                            Button {
                                Task {
                                    await ticketScanner.scanTicket(image: image)
                                    hasScanned = true
                                    applyScannedData()
                                }
                            } label: {
                                HStack {
                                    if ticketScanner.isProcessing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "doc.text.viewfinder")
                                    }
                                    Text(ticketScanner.isProcessing ? "Re-scan Ticket..." : "Re-scan Ticket")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: ticketScanner.isProcessing ? [Color.gray, Color.gray.opacity(0.8)] : [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(ticketScanner.isProcessing)
                        }
                        
                        if let ticketInfo = ticketScanner.ticketInfo {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Scanned Information")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                if let flightNumber = ticketInfo.flightNumber {
                                    TicketInfoRowView(label: "Flight", value: flightNumber)
                                }
                                if let trainNumber = ticketInfo.trainNumber {
                                    TicketInfoRowView(label: "Train", value: trainNumber)
                                }
                                if let departure = ticketInfo.departureLocation {
                                    TicketInfoRowView(label: "From", value: departure)
                                }
                                if let arrival = ticketInfo.arrivalLocation {
                                    TicketInfoRowView(label: "To", value: arrival)
                                }
                                if let depDate = ticketInfo.departureDate {
                                    TicketInfoRowView(label: "Date", value: depDate.formatted(date: .abbreviated, time: .omitted))
                                }
                                if let depTime = ticketInfo.departureTime {
                                    TicketInfoRowView(label: "Time", value: depTime)
                                }
                                if let seat = ticketInfo.seatNumber {
                                    TicketInfoRowView(label: "Seat", value: seat)
                                }
                                if let bookingRef = ticketInfo.bookingReference {
                                    TicketInfoRowView(label: "Booking Ref", value: bookingRef)
                                }
                                if let price = ticketInfo.price {
                                    TicketInfoRowView(label: "Price", value: String(format: "%.2f", price))
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    } else if let imageData = document.fileData {
                        ProgressView()
                            .frame(height: 250)
                            .onAppear {
                                loadImageAsync(from: imageData)
                            }
                    } else {
                        Image(systemName: document.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .frame(height: 250)
                    }
                }
                
                Section("Document Type") {
                    Picker("Type", selection: $documentType) {
                        Text("Ticket").tag("ticket")
                        Text("Receipt").tag("receipt")
                        Text("Reservation").tag("reservation")
                        Text("Passport").tag("passport")
                        Text("Visa").tag("visa")
                        Text("Travel Insurance").tag("insurance")
                        Text("Other").tag("other")
                    }
                }
                
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: $title)
                            .textInputAutocapitalization(.words)
                        
                        if title.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Title is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 2)
                        }
                    }
                    
                    TextField("", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                            .font(.headline)
                        TextField("", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    
                    if let dateBinding = Binding($date) {
                        DatePicker("Date", selection: dateBinding, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveDocument()
                        }
                        .disabled(!isFormValid || isSaving)
                    }
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func applyScannedData() {
        guard let ticketInfo = ticketScanner.ticketInfo else { return }
        
        // Auto-fill title if empty
        if title.isEmpty {
            if let flightNumber = ticketInfo.flightNumber {
                title = "Flight \(flightNumber)"
            } else if let trainNumber = ticketInfo.trainNumber {
                title = "Train \(trainNumber)"
            } else if let busNumber = ticketInfo.busNumber {
                title = "Bus \(busNumber)"
            }
        }
        
        // Auto-fill notes with extracted information
        var noteParts: [String] = []
        if !notes.isEmpty {
            noteParts.append(notes)
        }
        if let departure = ticketInfo.departureLocation, let arrival = ticketInfo.arrivalLocation {
            noteParts.append("\(departure) → \(arrival)")
        }
        if let depTime = ticketInfo.departureTime {
            noteParts.append("Departure: \(depTime)")
        }
        if let seat = ticketInfo.seatNumber {
            noteParts.append("Seat: \(seat)")
        }
        if let bookingRef = ticketInfo.bookingReference {
            noteParts.append("Booking: \(bookingRef)")
        }
        
        if !noteParts.isEmpty {
            notes = noteParts.joined(separator: "\n")
        }
        
        // Auto-fill amount
        if amountText.isEmpty, let price = ticketInfo.price {
            amountText = String(format: "%.2f", price)
        }
        
        // Auto-fill date
        if let depDate = ticketInfo.departureDate {
            date = depDate
        }
        
        // Update document type based on detected type
        if let detectedType = ticketInfo.ticketType {
            documentType = detectedType
        }
    }
    
    private func loadImageAsync(from data: Data) {
        Task {
            if let image = UIImage(data: data) {
                await MainActor.run {
                    loadedImage = image
                }
            }
        }
    }
    
    private func saveDocument() {
        // Validation
        guard isFormValid else {
            if title.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Please enter a document title"
            } else {
                errorMessage = "Please check your document details"
            }
            showErrorAlert = true
            return
        }
        
        guard !isSaving else { return }
        isSaving = true
        
        document.type = documentType
        document.title = title
        document.notes = notes
        document.amount = Double(amountText.isEmpty ? "0" : amountText) ?? nil
        document.date = date
        
        do {
            try modelContext.save()
            isSaving = false
            dismiss()
        } catch {
            isSaving = false
            #if DEBUG
            print("Failed to save document: \(error)")
            #endif
        }
    }
}

// MARK: - Ticket Info Row Helper
private struct TicketInfoRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

