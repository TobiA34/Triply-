//
//  LocationManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var locationError: String?
    
    private let locationManager = CLLocationManager()
    private let minimumUpdateDistance: CLLocationDistance = 10.0 // Update only if moved at least 10 meters
    private var isUpdatingLocation = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = minimumUpdateDistance
        // Initialize authorization status - will be updated via delegate callback
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        // Check current authorization status (may have changed)
        let currentStatus = locationManager.authorizationStatus
        
        guard currentStatus == .authorizedWhenInUse || currentStatus == .authorizedAlways else {
            // Update published property to reflect current status
            authorizationStatus = currentStatus
            requestAuthorization()
            return
        }
        
        // Ensure published property is in sync
        authorizationStatus = currentStatus
        
        // Only start if not already updating
        guard !isUpdatingLocation else { return }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
        
        // Also request one-time location for immediate update
        locationManager.requestLocation()
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func getLocationName(for location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                Task { @MainActor in
                    self?.locationError = "Geocoding failed: \(error.localizedDescription)"
                }
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first {
                let name = placemark.name ?? placemark.locality ?? placemark.country ?? "Unknown Location"
                completion(name)
            } else {
                Task { @MainActor in
                    self?.locationError = "No location name found"
                }
                completion(nil)
            }
        }
    }
    
    func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000.0 // Return in kilometers
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    // Delegate methods must be nonisolated because CLLocationManager calls them from background threads
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard let location = locations.last else { return }
            
            // Accept first location or locations with good accuracy
            let isFirstLocation = self.currentLocation == nil
            let hasGoodAccuracy = location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 100
            
            // For first location, accept even if accuracy is not perfect
            // For subsequent locations, filter by accuracy and distance
            if isFirstLocation {
                // Accept first location regardless of accuracy (will improve over time)
                self.currentLocation = location
                self.locationError = nil
                print("📍 LocationManager: First location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            } else if hasGoodAccuracy {
                // For subsequent locations, check distance
                if let currentLocation = self.currentLocation {
                    let distance = location.distance(from: currentLocation)
                    // Only update if moved at least minimumUpdateDistance meters
                    if distance >= self.minimumUpdateDistance {
                        self.currentLocation = location
                        self.locationError = nil
                        print("📍 LocationManager: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    }
                } else {
                    // Shouldn't happen, but handle it
                    self.currentLocation = location
                    self.locationError = nil
                }
            } else {
                // Low accuracy location - log but don't update
                print("📍 LocationManager: Ignoring low accuracy location: \(location.horizontalAccuracy)m")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.locationError = error.localizedDescription
            self.isUpdatingLocation = false
            print("❌ LocationManager: Error - \(error.localizedDescription)")
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let newStatus = manager.authorizationStatus
            self.authorizationStatus = newStatus
            
            print("🔐 LocationManager: Authorization changed to: \(self.statusString(newStatus))")
            
            // If authorization was just granted, automatically start location updates
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                // Start updates if not already running
                if !self.isUpdatingLocation {
                    self.isUpdatingLocation = true
                    manager.startUpdatingLocation()
                    manager.requestLocation() // Request immediate location
                    print("📍 LocationManager: Auto-started location updates after authorization")
                }
            } else {
                // Stop updates if authorization was revoked
                self.isUpdatingLocation = false
                manager.stopUpdatingLocation()
            }
        }
    }
    
    // Helper method for debugging
    private func statusString(_ status: CLAuthorizationStatus) -> String {
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
