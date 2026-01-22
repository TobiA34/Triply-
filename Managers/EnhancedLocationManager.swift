//
//  EnhancedLocationManager.swift
//  Itinero
//
//  Enhanced Apple Location API integration with advanced features
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Location Status
enum LocationStatus {
    case notDetermined
    case restricted
    case denied
    case authorized
    case locating
    case located(CLLocation)
    case error(String)
}

// MARK: - Enhanced Location Manager
@MainActor
class EnhancedLocationManager: NSObject, ObservableObject {
    static let shared = EnhancedLocationManager()
    
    // Published properties
    @Published var status: LocationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isUpdatingLocation = false
    
    // Location accuracy
    @Published var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    @Published var distanceFilter: CLLocationDistance = 10.0 // meters
    
    // Location history
    @Published var locationHistory: [CLLocation] = []
    private let maxHistoryCount = 10
    
    // Geocoding
    @Published var currentPlacemark: CLPlacemark?
    @Published var currentAddress: String?
    
    // Location updates
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    // Core Location
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Combine
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
        authorizationStatus = locationManager.authorizationStatus
        updateStatus()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else {
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        guard authorizationStatus == .notDetermined || authorizationStatus == .authorizedWhenInUse else {
            return
        }
        
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - Location Updates
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        
        guard !isUpdatingLocation else { return }
        
        isUpdatingLocation = true
        status = .locating
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        
        // Request immediate location
        locationManager.requestLocation()
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        
        if currentLocation != nil {
            status = .located(currentLocation!)
        } else {
            status = .authorized
        }
    }
    
    // MARK: - Single Location Request
    func requestLocation() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            throw LocationError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            // Set up one-time location handler
            let handler: (CLLocation) -> Void = { location in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: location)
            }
            
            locationUpdateHandler = handler
            
            // Request location
            locationManager.requestLocation()
            
            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
        }
    }
    
    // MARK: - Location Accuracy
    func setAccuracy(_ accuracy: CLLocationAccuracy) {
        desiredAccuracy = accuracy
        locationManager.desiredAccuracy = accuracy
    }
    
    func setDistanceFilter(_ distance: CLLocationDistance) {
        distanceFilter = distance
        locationManager.distanceFilter = distance
    }
    
    // MARK: - Geocoding
    func geocodeLocation(_ location: CLLocation) async throws -> CLPlacemark {
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else {
            throw LocationError.geocodingFailed
        }
        return placemark
    }
    
    func geocodeAddress(_ address: String) async throws -> [CLPlacemark] {
        return try await geocoder.geocodeAddressString(address)
    }
    
    func updateCurrentAddress() async {
        guard let location = currentLocation else { return }
        
        do {
            let placemark = try await geocodeLocation(location)
            await MainActor.run {
                self.currentPlacemark = placemark
                self.currentAddress = formatAddress(from: placemark)
            }
        } catch {
            await MainActor.run {
                self.locationError = "Geocoding failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Distance Calculation
    func distance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        return from.distance(from: to)
    }
    
    func distanceToLocation(_ location: CLLocation) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        return current.distance(from: location)
    }
    
    func formattedDistance(to location: CLLocation) -> String? {
        guard let distance = distanceToLocation(location) else { return nil }
        
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
    
    // MARK: - Location History
    private func addToHistory(_ location: CLLocation) {
        locationHistory.append(location)
        if locationHistory.count > maxHistoryCount {
            locationHistory.removeFirst()
        }
    }
    
    func clearHistory() {
        locationHistory.removeAll()
    }
    
    // MARK: - Helper Methods
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        if let zip = placemark.postalCode {
            components.append(zip)
        }
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }
    
    private func updateStatus() {
        switch authorizationStatus {
        case .notDetermined:
            status = .notDetermined
        case .restricted:
            status = .restricted
        case .denied:
            status = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = currentLocation {
                status = .located(location)
            } else if isUpdatingLocation {
                status = .locating
            } else {
                status = .authorized
            }
        @unknown default:
            status = .notDetermined
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension EnhancedLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self = self, let location = locations.last else { return }
            
            // Update current location
            let isFirstLocation = self.currentLocation == nil
            let hasGoodAccuracy = location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 100
            
            if isFirstLocation || hasGoodAccuracy {
                self.currentLocation = location
                self.addToHistory(location)
                self.status = .located(location)
                self.locationError = nil
                
                // Call update handler if set
                self.locationUpdateHandler?(location)
                self.locationUpdateHandler = nil
                
                // Update address
                Task {
                    await self.updateCurrentAddress()
                }
                
                print("📍 EnhancedLocationManager: Location updated - \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            // kCLErrorDomain error 0 (.locationUnknown) is transient – don't treat as a hard error.
            if let clError = error as? CLError, clError.code == .locationUnknown {
                // Keep trying if we're supposed to be updating; just log quietly.
                self.locationError = nil
                self.status = .locating
                print("⚠️ EnhancedLocationManager: Location temporarily unavailable (.locationUnknown)")
                return
            }

            self.locationError = error.localizedDescription
            self.isUpdatingLocation = false
            self.status = .error(error.localizedDescription)
            
            print("❌ EnhancedLocationManager: Error - \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let newStatus = manager.authorizationStatus
            self.authorizationStatus = newStatus
            self.updateStatus()
            
            print("🔐 EnhancedLocationManager: Authorization changed to \(self.statusString(newStatus))")
            
            // Auto-start if authorized
            if (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) && !self.isUpdatingLocation {
                self.isUpdatingLocation = true
                manager.startUpdatingLocation()
                manager.requestLocation()
            } else if newStatus == .denied || newStatus == .restricted {
                self.isUpdatingLocation = false
                manager.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated private func statusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown"
        }
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case notAuthorized
    case timeout
    case geocodingFailed
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location authorization not granted"
        case .timeout:
            return "Location request timed out"
        case .geocodingFailed:
            return "Failed to geocode location"
        case .locationUnavailable:
            return "Location is currently unavailable"
        }
    }
}

