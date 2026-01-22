//
//  SocialMediaImportView.swift
//  Itinero
//
//  View for importing locations from social media
//

import SwiftUI
import SwiftData

struct SocialMediaImportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var socialManager = SocialMediaManager.shared
    @StateObject private var proLimiter = ProLimiter.shared
    
    let trip: TripModel
    @State private var urlText = ""
    @State private var extractedLocation: ExtractedLocation?
    @State private var showingSuccess = false
    @State private var showingPaywall = false
    @State private var errorMessage: String?
    @State private var showingAddOptions = false
    @StateObject private var locationManager = EnhancedLocationManager.shared
    
    var body: some View {
        NavigationStack {
            if !proLimiter.isPro {
                // Paywall Gate
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 60)
                    
                    Text("Social Media Import")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    
                    Text("Import saved posts from Instagram and Pinterest to turn them into trip destinations instantly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("Import from Instagram saved posts", "camera.fill")
                        featureRow("Import from Pinterest boards", "pin.fill")
                        featureRow("Auto-extract locations and photos", "sparkles")
                        featureRow("One-tap destination creation", "hand.tap.fill")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Pro")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                Form {
                Section {
                    TextField("Paste Instagram/TikTok URL", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    if socialManager.isProcessing {
                        HStack {
                            ProgressView()
                            Text("Extracting location...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Social Media Link")
                } footer: {
                    Text("Paste a link from Instagram or TikTok to automatically extract location information.")
                }
                
                if let location = extractedLocation {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            // Video Title
                            if let videoTitle = location.videoTitle, !videoTitle.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Video Title")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(videoTitle)
                                        .font(.headline)
                                }
                                Divider()
                            }
                            
                            // Location Name
                            HStack {
                                Image(systemName: location.sourceType.icon)
                                    .foregroundColor(location.sourceType.color)
                                Text(location.name)
                                    .font(.headline)
                            }
                            
                            // Description
                            if let description = location.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                Divider()
                            }
                            
                            // Address
                            if let address = location.address {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Source URL
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.secondary)
                                Text(location.sourceURL)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Extracted Information")
                    }
                    
                    Section {
                        Button {
                            showingAddOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Trip")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Section {
                    Button {
                        // Try to extract from clipboard
                        if let clipboardText = UIPasteboard.general.string {
                            urlText = clipboardText
                            extractLocation()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Paste from Clipboard")
                        }
                    }
                }
            }
            .navigationTitle("Import from Social")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: urlText) { _, newValue in
                if !newValue.isEmpty && (newValue.contains("instagram.com") || newValue.contains("tiktok.com")) {
                    extractLocation()
                }
            }
            .overlay {
                if showingSuccess {
                    SuccessCheckmark()
                        .transition(.scale)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showingSuccess = false
                                dismiss()
                            }
                        }
                }
            }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(isPresented: $showingAddOptions) {
            if let location = extractedLocation {
                AddOptionsSheet(
                    location: location,
                    trip: trip,
                    onAddDestination: {
                        showingAddOptions = false
                        addLocationToTrip(location)
                    },
                    onAddToItinerary: {
                        showingAddOptions = false
                        addToItinerary(location)
                    }
                )
            }
        }
    }
    
    private func featureRow(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
        }
    }
    
    private func extractLocation() {
        errorMessage = nil
        Task {
            let location = await socialManager.extractLocation(from: urlText)
            await MainActor.run {
                if let location = location {
                    extractedLocation = location
                    // If we have a location name but no coordinates, try to geocode it
                    if location.latitude == nil || location.longitude == nil {
                        geocodeLocationName(location.name)
                    }
                } else {
                    errorMessage = "Could not extract location from URL. Make sure it's a valid Instagram or TikTok link."
                    extractedLocation = nil
                }
            }
        }
    }
    
    private func geocodeLocationName(_ name: String) {
        guard let currentLocation = extractedLocation else { return }
        
        Task {
            do {
                let placemarks = try await locationManager.geocodeAddress(name)
                if let placemark = placemarks.first,
                   let coordinate = placemark.location?.coordinate {
                    await MainActor.run {
                        // Update extracted location with coordinates
                        extractedLocation = ExtractedLocation(
                            name: currentLocation.name,
                            address: currentLocation.address ?? placemark.name,
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            sourceURL: currentLocation.sourceURL,
                            sourceType: currentLocation.sourceType,
                            imageURL: currentLocation.imageURL,
                            videoTitle: currentLocation.videoTitle,
                            description: currentLocation.description
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    print("Geocoding failed: \(error.localizedDescription)")
                    // Don't show error - location name is still valid
                }
            }
        }
    }
    
    private func addLocationToTrip(_ location: ExtractedLocation) {
        // Validate that we have at least a name
        guard !location.name.isEmpty else {
            errorMessage = "Location name is required"
            return
        }
        
        let destination = DestinationModel(
            name: location.name,
            address: location.address ?? "",
            notes: "Imported from \(location.sourceType == .instagram ? "Instagram" : location.sourceType == .tiktok ? "TikTok" : "Social Media")",
            order: trip.destinations?.count ?? 0,
            latitude: location.latitude,
            longitude: location.longitude
        )
        
        modelContext.insert(destination)
        
        if trip.destinations == nil {
            trip.destinations = []
        }
        
        trip.destinations?.append(destination)
        
        Task { @MainActor in
            do {
                try modelContext.save()
                HapticManager.shared.success()
                showingSuccess = true
                errorMessage = nil
            } catch {
                print("Failed to save destination: \(error)")
                errorMessage = "Failed to save destination: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
    
    private func addToItinerary(_ location: ExtractedLocation) {
        // Calculate default day (first day of trip)
        let calendar = Calendar.current
        let day = 1
        let date = trip.startDate
        
        // Use video title if available, otherwise use location name
        let title = location.videoTitle ?? location.name
        let details = location.description ?? "Imported from \(location.sourceType == .instagram ? "Instagram" : location.sourceType == .tiktok ? "TikTok" : "Social Media")"
        let locationString = location.address ?? location.name
        
        let itineraryItem = ItineraryItem(
            day: day,
            date: date,
            title: title,
            details: details,
            time: "",
            location: locationString,
            order: trip.itinerary?.count ?? 0,
            isBooked: false,
            bookingReference: "",
            reminderDate: nil,
            category: "Activity",
            estimatedCost: nil,
            estimatedDuration: nil,
            photoData: nil,
            sourceURL: location.sourceURL,  // Save the TikTok/Instagram URL
            travelTimeFromPrevious: nil
        )
        
        modelContext.insert(itineraryItem)
        
        if trip.itinerary == nil {
            trip.itinerary = []
        }
        
        trip.itinerary?.append(itineraryItem)
        
        Task { @MainActor in
            do {
                try modelContext.save()
                HapticManager.shared.success()
                showingSuccess = true
                errorMessage = nil
            } catch {
                print("Failed to save itinerary item: \(error)")
                errorMessage = "Failed to save to itinerary: \(error.localizedDescription)"
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Add Options Sheet
struct AddOptionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let location: ExtractedLocation
    let trip: TripModel
    let onAddDestination: () -> Void
    let onAddToItinerary: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Choose how to add this content to your trip")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button {
                        onAddDestination()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add as Destination")
                                    .font(.headline)
                                Text("Save as a location to visit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                    
                    Button {
                        onAddToItinerary()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add to Itinerary")
                                    .font(.headline)
                                Text("Add as an activity with video info")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Add to Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

