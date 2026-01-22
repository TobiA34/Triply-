//
//  TravelDocumentsView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import SwiftData

struct TravelDocumentsView: View {
    let trip: TripModel
    @Environment(\.modelContext) private var modelContext
    @State private var documents: [TravelDocument] = []
    @State private var showingAddDocument = false
    @State private var selectedDocument: TravelDocument?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Travel Documents")
                        .font(.title2.bold())
                    Text("Track your passports, visas, and travel documents")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Document Checklist
                VStack(spacing: 12) {
                    ForEach(TravelDocumentType.allCases, id: \.self) { type in
                        DocumentChecklistItem(
                            type: type,
                            document: documents.first { $0.type == type },
                            onAdd: {
                                selectedDocument = documents.first { $0.type == type }
                                showingAddDocument = true
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Additional Documents
                if !documents.filter({ !TravelDocumentType.allCases.contains($0.type) }).isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Documents")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(documents.filter { !TravelDocumentType.allCases.contains($0.type) }) { document in
                            TravelDocumentCard(document: document) {
                                selectedDocument = document
                                showingAddDocument = true
                            } onDelete: {
                                deleteDocument(document)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Add Custom Document Button
                Button(action: {
                    selectedDocument = nil
                    showingAddDocument = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Custom Document")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadDocuments()
        }
        .fullScreenCover(isPresented: $showingAddDocument) {
            AddTravelDocumentView(
                document: selectedDocument,
                onSave: { document in
                    if let index = documents.firstIndex(where: { $0.id == document.id }) {
                        documents[index] = document
                    } else {
                        documents.append(document)
                    }
                    saveDocuments()
                }
            )
        }
    }
    
    private func loadDocuments() {
        if let data = UserDefaults.standard.data(forKey: "travel_documents_\(trip.id.uuidString)"),
           let docs = try? JSONDecoder().decode([TravelDocument].self, from: data) {
            documents = docs
        }
    }
    
    private func saveDocuments() {
        if let data = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(data, forKey: "travel_documents_\(trip.id.uuidString)")
        }
    }
    
    private func deleteDocument(_ document: TravelDocument) {
        documents.removeAll { $0.id == document.id }
        saveDocuments()
    }
}

struct TravelDocument: Identifiable, Codable {
    let id: UUID
    var type: TravelDocumentType
    var documentNumber: String
    var expiryDate: Date?
    var issueDate: Date?
    var issuingCountry: String
    var notes: String
    var isUploaded: Bool
    
    init(
        id: UUID = UUID(),
        type: TravelDocumentType,
        documentNumber: String,
        expiryDate: Date? = nil,
        issueDate: Date? = nil,
        issuingCountry: String = "",
        notes: String = "",
        isUploaded: Bool = false
    ) {
        self.id = id
        self.type = type
        self.documentNumber = documentNumber
        self.expiryDate = expiryDate
        self.issueDate = issueDate
        self.issuingCountry = issuingCountry
        self.notes = notes
        self.isUploaded = isUploaded
    }
    
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }
    
    var isExpiringSoon: Bool {
        guard let expiryDate = expiryDate else { return false }
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return daysUntilExpiry > 0 && daysUntilExpiry <= 90
    }
}

enum TravelDocumentType: String, Codable, CaseIterable {
    case passport = "passport"
    case visa = "visa"
    case travelInsurance = "travelInsurance"
    case driverLicense = "driverLicense"
    case healthCertificate = "healthCertificate"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .passport: return "Passport"
        case .visa: return "Visa"
        case .travelInsurance: return "Travel Insurance"
        case .driverLicense: return "Driver's License"
        case .healthCertificate: return "Health Certificate"
        case .custom: return "Custom Document"
        }
    }
    
    var icon: String {
        switch self {
        case .passport: return "book.closed.fill"
        case .visa: return "stamp.fill"
        case .travelInsurance: return "shield.fill"
        case .driverLicense: return "car.fill"
        case .healthCertificate: return "cross.case.fill"
        case .custom: return "doc.fill"
        }
    }
}

private struct DocumentChecklistItem: View {
    let type: TravelDocumentType
    let document: TravelDocument?
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(document != nil ? .green : .secondary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.headline)
                if let document = document {
                    if document.isExpired {
                        Text("Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if document.isExpiringSoon {
                        Text("Expiring Soon")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let expiryDate = document.expiryDate {
                        Text("Expires" + ": \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Added")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Not Added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: document != nil ? "pencil.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct TravelDocumentCard: View {
    let document: TravelDocument
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: document.type.icon)
                    .foregroundColor(.blue)
                Text(document.type.displayName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            if !document.documentNumber.isEmpty {
                TravelDocumentInfoRow(label: "Document Number", value: document.documentNumber)
            }
            
            if let expiryDate = document.expiryDate {
                HStack {
                    Text("Expires")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(expiryDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(document.isExpired ? .red : document.isExpiringSoon ? .orange : .primary)
                }
            }
            
            if !document.notes.isEmpty {
                Text(document.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

private struct TravelDocumentInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

private struct AddTravelDocumentView: View {
    @Environment(\.dismiss) var dismiss
    let document: TravelDocument?
    let onSave: (TravelDocument) -> Void
    
    @State private var selectedType: TravelDocumentType = .passport
    @State private var documentNumber = ""
    @State private var expiryDate: Date? = nil
    @State private var issueDate: Date? = nil
    @State private var issuingCountry = ""
    @State private var notes = ""
    @State private var showExpiryDatePicker = false
    @State private var showIssueDatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Information") {
                    Picker("Document Type", selection: $selectedType) {
                        ForEach(TravelDocumentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Document Number", text: $documentNumber)
                    
                    TextField("Issuing Country", text: $issuingCountry)
                }
                
                Section("Dates") {
                    DatePicker("Issue Date", selection: Binding(
                        get: { issueDate ?? Date() },
                        set: { issueDate = $0 }
                    ), displayedComponents: .date)
                    
                    DatePicker("Expiry Date", selection: Binding(
                        get: { expiryDate ?? Date() },
                        set: { expiryDate = $0 }
                    ), displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Add any additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(document != nil ? "Edit Document" : "Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let doc = TravelDocument(
                            id: document?.id ?? UUID(),
                            type: selectedType,
                            documentNumber: documentNumber,
                            expiryDate: expiryDate,
                            issueDate: issueDate,
                            issuingCountry: issuingCountry,
                            notes: notes
                        )
                        onSave(doc)
                        dismiss()
                    }
                    .disabled(documentNumber.isEmpty)
                }
            }
            .onAppear {
                if let document = document {
                    selectedType = document.type
                    documentNumber = document.documentNumber
                    expiryDate = document.expiryDate
                    issueDate = document.issueDate
                    issuingCountry = document.issuingCountry
                    notes = document.notes
                }
            }
        }
    }
}

#Preview {
    TravelDocumentsView(trip: TripModel(
        name: "Sample Trip",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    ))
}


