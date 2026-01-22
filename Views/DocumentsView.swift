//
//  DocumentsView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation

struct DocumentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripDocument.createdAt, order: .reverse) private var allDocuments: [TripDocument]
    @Query(sort: \DocumentFolder.createdAt, order: .forward) private var allFolders: [DocumentFolder]
    @StateObject private var permissionManager = CameraPermissionManager.shared
    @State private var showingDocumentPicker = false
    @State private var showingAddDocument = false
    @State private var selectedDocument: TripDocument?
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingImageDocumentForm = false
    @State private var shouldShowFormAfterImageCapture = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showingCreateFolder = false
    @State private var selectedFolder: DocumentFolder?
    // Batch scanning removed - use single receipt scanning in Expenses instead
    
    let trip: TripModel
    
    var tripDocuments: [TripDocument] {
        // Filter documents for this trip that are not in folders
        allDocuments.filter { doc in
            (doc.trip?.id == trip.id || 
             doc.relatedItineraryItem != nil || 
             doc.relatedExpense != nil) &&
            doc.folder == nil
        }
    }
    
    var tripFolders: [DocumentFolder] {
        // Filter folders for this trip
        allFolders.filter { folder in
            folder.trip?.id == trip.id
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add Document Buttons Section
                    VStack(spacing: 12) {
                        // Primary Actions Row
                        HStack(spacing: 12) {
                            Button {
                                showingDocumentPicker = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "doc.fill")
                                        .font(.title2)
                                    Text("Add Details")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                shouldShowFormAfterImageCapture = true
                                Task {
                                    await requestCameraAccess()
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Take Photo")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        }
                        
                        // Secondary Actions Row
                        HStack(spacing: 12) {
                            // Batch scanning removed - use single receipt scanning in Expenses instead
                            
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.headline)
                                    Text("From Library")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Folders Section
                    if !tripFolders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Folders")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(tripFolders.count == 1 ? String(format: "%d folder", tripFolders.count) : String(format: "%d folders", tripFolders.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(tripFolders) { folder in
                                        FolderCard(folder: folder)
                                            .onTapGesture {
                                                selectedFolder = folder
                                            }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Documents List
                    if !tripDocuments.isEmpty || !tripFolders.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            if !tripDocuments.isEmpty {
                                HStack {
                                    Text("All")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(tripDocuments.count == 1 ? String(format: "%d document", tripDocuments.count) : String(format: "%d documents", tripDocuments.count))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 20)
                                
                                ForEach(tripDocuments) { document in
                                    DocumentCard(document: document)
                                        .onTapGesture {
                                            selectedDocument = document
                                        }
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        EmptyDocumentsView()
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView(trip: trip)
            }
            .sheet(isPresented: $showingImagePicker) {
                CameraImagePicker(image: $selectedImage, shouldShowForm: $showingImageDocumentForm, sourceType: .camera)
                    .interactiveDismissDisabled(false) // Allow swipe to dismiss
            }
            .fullScreenCover(isPresented: $showingImageDocumentForm) {
                if let image = selectedImage {
                    ImageDocumentFormView(trip: trip, image: image)
                        .onDisappear {
                            // Reset image when form is dismissed
                            selectedImage = nil
                            shouldShowFormAfterImageCapture = false
                        }
                }
            }
            .sheet(item: $selectedDocument) { document in
                DocumentDetailView(document: document)
            }
            .fullScreenCover(isPresented: $showingCreateFolder) {
                CreateFolderView(trip: trip)
            }
            .sheet(item: $selectedFolder) { folder in
                FolderDetailView(folder: folder)
            }
            // Batch scanning removed - use single receipt scanning in Expenses instead
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let item = newValue {
                        do {
                            guard let data = try? await item.loadTransferable(type: Data.self) else {
                                return
                            }
                            
                            // Process image on background thread
                            guard let image = UIImage(data: data) else { return }
                            
                            // Resize if too large
                            let processedImage = image.size.width > 1920 || image.size.height > 1920
                                ? image.resized(to: CGSize(width: 1920, height: 1920))
                                : image
                            
                            await MainActor.run {
                                selectedImage = processedImage
                                showingImageDocumentForm = true
                            }
                        } catch {
                            #if DEBUG
                            print("Error loading photo: \(error)")
                            #endif
                        }
                    }
                }
            }
            .onChange(of: selectedImage) { _, newValue in
                // Show form if image was captured from camera
                if newValue != nil && shouldShowFormAfterImageCapture {
                    // Small delay to ensure picker is fully dismissed
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        if selectedImage != nil && !showingImageDocumentForm {
                            showingImageDocumentForm = true
                            shouldShowFormAfterImageCapture = false
                        }
                    }
                }
            }
            .onChange(of: showingImagePicker) { _, isShowing in
                // When picker is dismissed, check if we have an image to show
                if !isShowing {
                    if selectedImage != nil && shouldShowFormAfterImageCapture {
                        // Small delay to ensure picker is fully dismissed
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                            if selectedImage != nil && !showingImageDocumentForm {
                                showingImageDocumentForm = true
                                shouldShowFormAfterImageCapture = false
                            }
                        }
                    } else if !shouldShowFormAfterImageCapture {
                        // User cancelled - reset flag
                        shouldShowFormAfterImageCapture = false
                    }
                }
            }
            .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(permissionAlertMessage)
            }
        }
    }
    
    private func requestCameraAccess() async {
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            await MainActor.run {
                permissionAlertMessage = "Camera is not available on this device."
                showingPermissionAlert = true
            }
            return
        }
        
        // Check current permission status
        let status = permissionManager.checkCameraPermission()
        
        switch status {
        case .authorized:
            await MainActor.run {
                showingImagePicker = true
            }
        case .denied, .restricted:
            await MainActor.run {
                permissionAlertMessage = "Camera access is denied. Please enable it in Settings to take photos of documents."
                showingPermissionAlert = true
                shouldShowFormAfterImageCapture = false // Reset flag if permission denied
            }
        case .notDetermined:
            // Request permission
            let granted = await permissionManager.requestCameraPermission()
            await MainActor.run {
                if granted {
                    showingImagePicker = true
                } else {
                    permissionAlertMessage = "Camera access is required to take photos of documents. Please enable it in Settings."
                    showingPermissionAlert = true
                    shouldShowFormAfterImageCapture = false // Reset flag if permission denied
                }
            }
        }
    }
}

// MARK: - Ticket Info Row Helper
private struct TicketInfoRow: View {
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

// MARK: - Folder Card
struct FolderCard: View {
    let folder: DocumentFolder
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: folder.color)?.opacity(0.15) ?? Color.blue.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: folder.icon)
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: folder.color) ?? .blue)
            }
            
            Text(folder.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            HStack(spacing: 4) {
                Image(systemName: "doc.fill")
                    .font(.caption2)
                Text("\(folder.documentCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct DocumentCard: View {
    let document: TripDocument
    @State private var loadedImage: UIImage?
    
    var body: some View {
        HStack(spacing: 16) {
            // Show image if available, otherwise show icon
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(10)
                    .clipped()
            } else if let imageData = document.fileData {
                // Load image asynchronously
                ProgressView()
                    .frame(width: 50, height: 50)
                    .onAppear {
                        loadImageAsync(from: imageData)
                    }
            } else {
                Image(systemName: document.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                
                Text(document.type.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let date = document.date {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let amount = document.amount {
                Text(SettingsManager.shared.formatAmount(amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func loadImageAsync(from data: Data) {
        Task {
            // Load and create thumbnail on background thread for better performance
            let thumbnail: UIImage? = await Task.detached(priority: .utility) {
                guard let image = UIImage(data: data) else { return nil as UIImage? }
                // Create thumbnail for faster display (50x50 for list view)
                return image.thumbnail(size: 50)
            }.value
            
            await MainActor.run {
                loadedImage = thumbnail
            }
        }
    }
}

struct EmptyDocumentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No documents yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add tickets, receipts, and important documents for your trip")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

struct DocumentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dataManager = StructuredDataManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var documentType = "ticket"
    @State private var title = ""
    @State private var description = ""
    @State private var amount: Double?
    @State private var amountText = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    let trip: TripModel
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Document Type") {
                    Picker("Type", selection: $documentType) {
                        Text("Ticket").tag("ticket")
                        Text("Receipt").tag("receipt")
                        Text("Reservation").tag("reservation")
                        Text("Passport").tag("passport")
                        Text("Visa").tag("visa")
                        Text("Insurance").tag("insurance")
                        Text("Other").tag("other")
                    }
                }
                
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: $title)
                            .foregroundColor(.primary)
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
                    
                    TextField("", text: $description, axis: .vertical)
                        .foregroundColor(.primary)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                            .font(.headline)
                        TextField("", text: $amountText)
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                            .onChange(of: amountText) { _, newValue in
                                amount = Double(newValue)
                            }
                    }
                }
            }
            .navigationTitle("Add Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDocument()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Validation Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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
        
        let structuredDoc = StructuredDocument(
            id: UUID().uuidString,
            type: documentType,
            title: title,
            description: description.isEmpty ? nil : description,
            fileName: nil,
            date: ISO8601DateFormatter().string(from: Date()),
            amount: amount,
            relatedItemId: nil
        )
        
        Task {
            do {
                try await dataManager.saveDocument(structuredDoc, to: trip, in: modelContext)
                await MainActor.run {
                    dismiss()
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct DocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let document: TripDocument
    @State private var loadedImage: UIImage?
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document Image or Icon
                    HStack {
                        Spacer()
                        if let image = loadedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 350)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        } else if let imageData = document.fileData {
                            ProgressView()
                                .frame(height: 300)
                                .onAppear {
                                    loadImageAsync(from: imageData)
                                }
                        } else {
                            Image(systemName: document.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DocumentInfoRow(label: "Title", value: document.title)
                        DocumentInfoRow(label: "Type", value: document.type.capitalized)
                        
                        if !document.notes.isEmpty {
                            DocumentInfoRow(label: "Notes", value: document.notes)
                        }
                        
                        if let date = document.date {
                            DocumentInfoRow(label: "Date", value: date, style: .date)
                        }
                        
                        if let amount = document.amount {
                            DocumentInfoRow(label: "Amount", value: SettingsManager.shared.formatAmount(amount))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            showingEditSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Document")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if let trip = document.trip {
                            NavigationLink {
                                MoveToFolderView(document: document, trip: trip)
                            } label: {
                                HStack {
                                    Image(systemName: "folder")
                                    Text("Move to Folder")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Document")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingEditSheet) {
                if let trip = document.trip {
                    EditDocumentView(document: document, trip: trip)
                }
            }
            .alert("Delete Document", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteDocument()
                }
            } message: {
                Text("Are you sure you want to delete this document?")
            }
        }
    }
    
    private func loadImageAsync(from data: Data) {
        Task {
            let image = UIImage(data: data)
            await MainActor.run {
                loadedImage = image
            }
        }
    }
    
    private func deleteDocument() {
        modelContext.delete(document)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete document: \(error)")
        }
    }
}

// MARK: - Image Document Form
struct ImageDocumentFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ticketScanner = TicketScannerManager()
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var documentType = "ticket"
    @State private var title = ""
    @State private var notes = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var isSaving = false
    @State private var hasScanned = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    let trip: TripModel
    let image: UIImage
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Image Preview") {
                    ZStack(alignment: .top) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                            .cornerRadius(8)
                            .overlay(
                                ScanningOverlay(isScanning: $ticketScanner.isProcessing)
                                    .animation(.easeInOut(duration: 0.3), value: ticketScanner.isProcessing)
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
                    
                    if !hasScanned {
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
                                Text(ticketScanner.isProcessing ? "Scanning Ticket..." : "Scan Ticket for Details")
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
                                TicketInfoRow(label: "Flight", value: flightNumber)
                            }
                            if let trainNumber = ticketInfo.trainNumber {
                                TicketInfoRow(label: "Train", value: trainNumber)
                            }
                            if let departure = ticketInfo.departureLocation {
                                TicketInfoRow(label: "From", value: departure)
                            }
                            if let arrival = ticketInfo.arrivalLocation {
                                TicketInfoRow(label: "To", value: arrival)
                            }
                            if let depDate = ticketInfo.departureDate {
                                TicketInfoRow(label: "Date", value: depDate.formatted(date: .abbreviated, time: .omitted))
                            }
                            if let depTime = ticketInfo.departureTime {
                                TicketInfoRow(label: "Time", value: depTime)
                            }
                            if let seat = ticketInfo.seatNumber {
                                TicketInfoRow(label: "Seat", value: seat)
                            }
                            if let bookingRef = ticketInfo.bookingReference {
                                TicketInfoRow(label: "Booking Ref", value: bookingRef)
                            }
                            if let price = ticketInfo.price {
                                TicketInfoRow(label: "Price", value: String(format: "%.2f", price))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    if let error = ticketScanner.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Document Type") {
                    Picker("Type", selection: $documentType) {
                        Text("Ticket").tag("ticket")
                        Text("Receipt").tag("receipt")
                        Text("Reservation").tag("reservation")
                        Text("Passport").tag("passport")
                        Text("Visa").tag("visa")
                        Text("Insurance").tag("insurance")
                        Text("Other").tag("other")
                    }
                }
                
                Section("Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("", text: $title)
                            .foregroundColor(.primary)
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
                        .foregroundColor(.primary)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text(settingsManager.currentCurrency.symbol)
                            .foregroundColor(.secondary)
                            .font(.headline)
                        TextField("", text: $amountText)
                            .foregroundColor(.primary)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Document")
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
            .onAppear {
                // Auto-scan if document type is ticket
                if documentType == "ticket" && !hasScanned {
                    Task {
                        await ticketScanner.scanTicket(image: image)
                        hasScanned = true
                        applyScannedData()
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
        
        // Auto-fill title
        if title.isEmpty {
            if let flightNumber = ticketInfo.flightNumber {
                title = "Flight \(flightNumber)"
            } else if let trainNumber = ticketInfo.trainNumber {
                title = "Train \(trainNumber)"
            } else if let busNumber = ticketInfo.busNumber {
                title = "Bus \(busNumber)"
            } else {
                title = "Ticket"
            }
        }
        
        // Auto-fill notes with extracted information
        var noteParts: [String] = []
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
        if let passenger = ticketInfo.passengerName {
            noteParts.append("Passenger: \(passenger)")
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
        
        // Process image compression on background thread to prevent freezing
        Task { [image, documentType, title, notes, amountText, date, trip] in
            // Calculate optimal size (max 1920px on longest side)
            let maxDimension: CGFloat = 1920
            let size = image.size
            let aspectRatio = size.width / size.height
            
            var newSize: CGSize
            if size.width > size.height {
                if size.width > maxDimension {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = size
                }
            } else {
                if size.height > maxDimension {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                } else {
                    newSize = size
                }
            }
            
            // Resize and compress on background thread
            let resizedImage = await Task.detached(priority: .userInitiated) {
                image.resizedOptimized(to: newSize)
            }.value
            
            // Compress with optimal quality
            guard let imageData = resizedImage?.jpegData(compressionQuality: 0.75) else {
                await MainActor.run {
                    isSaving = false
                    HapticManager.shared.error()
                }
                return
            }
            
            let amount = Double(amountText.isEmpty ? "0" : amountText) ?? nil
            
            await MainActor.run {
                let document = TripDocument(
                    type: documentType,
                    title: title.isEmpty ? "Document \(Date().formatted(date: .abbreviated, time: .shortened))" : title,
                    notes: notes,
                    fileName: "\(title.isEmpty ? "document" : title.replacingOccurrences(of: " ", with: "_")).jpg",
                    fileData: imageData,
                    date: date,
                    amount: amount,
                    trip: trip,
                    folder: nil
                )
                
                modelContext.insert(document)
                
                do {
                    try modelContext.save()
                    isSaving = false
                    dismiss()
                    HapticManager.shared.success()
                } catch {
                    isSaving = false
                    print("Failed to save document: \(error)")
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - Camera Image Picker
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var shouldShowForm: Bool
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        
        // Check if source type is available
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            // Dismiss if camera not available
            DispatchQueue.main.async {
                self.dismiss()
            }
            return picker
        }
        
        // Additional safety check for camera
        if sourceType == .camera {
            // Verify camera permission before showing
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .denied || status == .restricted {
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Dismiss picker immediately to prevent freezing
            picker.dismiss(animated: true) {
                // Process image on background thread after dismissal
                Task.detached(priority: .userInitiated) { [weak self] in
                    guard let self = self else { return }
                    
                    let sourceImage: UIImage?
                    if let editedImage = info[.editedImage] as? UIImage {
                        sourceImage = editedImage
                    } else if let originalImage = info[.originalImage] as? UIImage {
                        sourceImage = originalImage
                    } else {
                        sourceImage = nil
                    }
                    
                    guard let image = sourceImage else {
                        await MainActor.run {
                            self.parent.dismiss()
                        }
                        return
                    }
                    
                    // Resize and compress on background thread
                    let processedImage = await self.processImageAsync(image)
                    
                    // Update UI on main thread
                    await MainActor.run {
                        self.parent.image = processedImage
                        // Dismiss picker first
                        self.parent.dismiss()
                        // Then show form after a short delay
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                            self.parent.shouldShowForm = true
                        }
                    }
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Reset flag if user cancels
            Task { @MainActor in
                // Access the parent's state through a binding or notification
                // For now, just dismiss - the flag will be reset when picker closes
            }
            parent.dismiss()
        }
        
        // Optimized async image processing
        private func processImageAsync(_ image: UIImage) async -> UIImage? {
            return await Task.detached(priority: .userInitiated) {
                // Calculate optimal size (max 1920px on longest side)
                let maxDimension: CGFloat = 1920
                let size = image.size
                let aspectRatio = size.width / size.height
                
                var newSize: CGSize
                if size.width > size.height {
                    if size.width > maxDimension {
                        newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                    } else {
                        newSize = size
                    }
                } else {
                    if size.height > maxDimension {
                        newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                    } else {
                        newSize = size
                    }
                }
                
                // Use optimized rendering for better performance
                return image.resizedOptimized(to: newSize)
            }.value
        }
    }
}

// Helper extension to resize images with optimization
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        return resizedOptimized(to: size)
    }
    
    // Optimized resizing method
    func resizedOptimized(to size: CGSize) -> UIImage? {
        // Use autoreleasepool to manage memory better
        return autoreleasepool {
            // Create optimized graphics context
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0 // Use device scale for better quality/speed balance
            format.opaque = false
            
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { context in
                // Use high quality interpolation for better results
                self.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    // Fast thumbnail generation for previews
    func thumbnail(size: CGFloat) -> UIImage? {
        let thumbnailSize = CGSize(width: size, height: size)
        return resizedOptimized(to: thumbnailSize)
    }
}

struct DocumentInfoRow: View {
    let label: String
    let value: String
    var style: Text.DateStyle? = nil
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, style: Text.DateStyle) {
        self.label = label
        self.value = ""
        self.style = style
        self.dateValue = value
    }
    
    private var dateValue: Date?
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            if let date = dateValue, let style = style {
                Text(date, style: style)
                    .fontWeight(.semibold)
            } else {
                Text(value)
                    .fontWeight(.semibold)
            }
        }
    }
}


//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation


// MARK: - Ticket Info Row Helper

// MARK: - Folder Card





// MARK: - Image Document Form

// MARK: - Camera Image Picker




//  Itinero
//
//  Created on 2024
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PhotosUI
import AVFoundation


// MARK: - Ticket Info Row Helper

// MARK: - Folder Card





// MARK: - Image Document Form

// MARK: - Camera Image Picker

// Helper extension to resize images with optimization