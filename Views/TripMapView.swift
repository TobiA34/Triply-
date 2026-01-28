//
//  TripMapView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI
import MapKit
import CoreLocation

struct TripMapView: View {
    @StateObject private var locationManager = EnhancedLocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @State private var refreshID = UUID()
    @State private var lastDestinationCount = 0
    @State private var lastDestinationCoords: [String] = []
    @State private var selectedDestination: DestinationModel? = nil
    @State private var showingDestinationActivities = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var trip: TripModel
    
    // Computed property to determine map center
    private var mapCenter: CLLocationCoordinate2D {
        // Priority: 1. Device location, 2. First destination, 3. Default (San Francisco)
        if let deviceLocation = locationManager.currentLocation {
            return deviceLocation.coordinate
        } else if let firstDestination = trip.destinations?.first,
                  let coord = firstDestination.coordinate {
            return coord
        } else {
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                // Show current user location if available
                if let currentLocation = locationManager.currentLocation {
                    Annotation("Your Location", coordinate: currentLocation.coordinate) {
                        VStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                            Text("You")
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Show route line connecting destinations (Roamy-style)
                if annotations.count > 1 {
                    MapPolyline(coordinates: annotations.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 3)
                }
                
                // Show trip destination annotations
                ForEach(Array(annotations.enumerated()), id: \.element.id) { index, annotation in
                    Annotation(annotation.title, coordinate: annotation.coordinate) {
                        Button {
                            if let destination = annotation.destination {
                                selectedDestination = destination
                                showingDestinationActivities = true
                                HapticManager.shared.selection()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 28, height: 28)
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                Text(annotation.title)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear {
                // Initialize tracking
                lastDestinationCount = trip.destinations?.count ?? 0
                lastDestinationCoords = (trip.destinations ?? []).compactMap { $0.coordinate }.map { "\($0.latitude),\($0.longitude)" }
                
                // Request location permission and start updates
                Task { @MainActor in
                    if locationManager.authorizationStatus == CLAuthorizationStatus.notDetermined {
                        await locationManager.requestAuthorization()
                    }
                    locationManager.startLocationUpdates()
                    
                    // Wait a moment for location, then update camera
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    updateCameraPosition()
                }
            }
            .onChange(of: trip.destinations?.count ?? 0) { oldCount, newCount in
                // Update camera when destinations change
                if newCount != lastDestinationCount {
                    lastDestinationCount = newCount
                    refreshID = UUID()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000) // Small delay to ensure data is saved
                        updateCameraPosition()
                    }
                }
            }
            .onChange(of: trip.destinations) { oldDestinations, newDestinations in
                // Watch for actual destination changes (coordinates, names, etc.)
                let newCoords = (newDestinations ?? []).compactMap { $0.coordinate }.map { "\($0.latitude),\($0.longitude)" }
                
                if newCoords != lastDestinationCoords {
                    // Defer state updates to avoid publishing during view updates
                    Task { @MainActor in
                        lastDestinationCoords = newCoords
                        refreshID = UUID()
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        updateCameraPosition()
                    }
                }
            }
            .onDisappear {
                // Optionally stop updates when view disappears to save battery
                // locationManager.stopLocationUpdates()
            }
            .onChange(of: locationManager.currentLocation) { _, newValue in
                // Update camera to include user location when it becomes available
                if let newLocation = newValue {
                    updateCameraPosition(includeUserLocation: newLocation)
                }
            }
            
            if annotations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No Destinations")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Add destinations with locations to see them on the map")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(16)
                .padding()
            }
        }
        .id(refreshID)
        .navigationTitle("Trip Map")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // Show location status - only show warning for actual errors, not just no location yet
                HStack(spacing: 4) {
                    if let error = locationManager.locationError,
                       locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        Button {
                            // Could show alert about enabling location
                        } label: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    } else if locationManager.currentLocation != nil {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if locationManager.authorizationStatus == .notDetermined {
                        // Don't show anything if location is not determined yet
                        EmptyView()
                    } else {
                        Image(systemName: "location.slash")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingDestinationActivities) {
            if let destination = selectedDestination {
                DestinationActivitiesView(
                    destination: destination,
                    trip: trip
                )
            }
        }
    }
    
    private var annotations: [MapAnnotation] {
        var annotations: [MapAnnotation] = []
        
        // Filter destinations with valid coordinates
        let destinationsWithCoords = (trip.destinations ?? []).filter { $0.coordinate != nil }
        
        guard !destinationsWithCoords.isEmpty else {
            return []
        }
        
        // Get optimized route order
        let sortedDestinations = TripOptimizer.shared.optimizeRoute(
            destinations: destinationsWithCoords
        )
        
        for destination in sortedDestinations {
            if let coordinate = destination.coordinate {
                annotations.append(MapAnnotation(
                    coordinate: coordinate,
                    title: destination.name,
                    destination: destination
                ))
            }
        }
        
        return annotations
    }
    
    private func updateCameraPosition(includeUserLocation userLocation: CLLocation? = nil) {
        var coordinates: [CLLocationCoordinate2D] = []
        
        // Add destination coordinates
        if let destinations = trip.destinations {
            coordinates.append(contentsOf: destinations.compactMap { $0.coordinate })
        }
        
        // Add user location if provided
        if let userLocation = userLocation {
            coordinates.append(userLocation.coordinate)
        }
        
        guard !coordinates.isEmpty else {
            // If no coordinates, use default center
            cameraPosition = .region(MKCoordinateRegion(
                center: mapCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        // Validate coordinates
        guard minLat != maxLat || minLon != maxLon else {
            // All coordinates are the same, use a default span
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinates.first ?? mapCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
            return
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Calculate span with padding
        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
        
        // Clamp span to reasonable values
        let clampedLatDelta = min(max(latDelta, 0.01), 180.0)
        let clampedLonDelta = min(max(lonDelta, 0.01), 360.0)
        
        let span = MKCoordinateSpan(
            latitudeDelta: clampedLatDelta,
            longitudeDelta: clampedLonDelta
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let destination: DestinationModel?
    
    init(coordinate: CLLocationCoordinate2D, title: String, destination: DestinationModel? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.destination = destination
    }
}



