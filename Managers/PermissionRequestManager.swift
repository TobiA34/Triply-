//
//  PermissionRequestManager.swift
//  Itinero
//
//  Created on 2025
//

import Foundation
import UIKit
import AVFoundation
import Photos
import CoreLocation
import Speech
import EventKit

@MainActor
class PermissionRequestManager: NSObject, ObservableObject {
    static let shared = PermissionRequestManager()
    
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var speechStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var microphoneStatus: AVAudioSession.RecordPermission = AVAudioSession.sharedInstance().recordPermission
    @Published var calendarStatus: EKAuthorizationStatus = .notDetermined
    
    @Published var hasRequestedPermissions = false
    
    private let locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        checkAllPermissions()
    }
    
    func checkAllPermissions() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        locationStatus = locationManager.authorizationStatus
        speechStatus = SFSpeechRecognizer.authorizationStatus()
        microphoneStatus = AVAudioSession.sharedInstance().recordPermission
        calendarStatus = EKEventStore.authorizationStatus(for: .event)
        
        // Check if we've requested permissions before
        hasRequestedPermissions = UserDefaults.standard.bool(forKey: "hasRequestedPermissions")
    }
    
    func requestAllPermissions() async {
        // Mark that we've requested permissions
        await MainActor.run {
            UserDefaults.standard.set(true, forKey: "hasRequestedPermissions")
        }
        
        // Request camera - must be on main thread
        if cameraStatus == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
        
        // Request photo library
        if photoLibraryStatus == .notDetermined {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                self.photoLibraryStatus = status
            }
        }
        
        // Request location - must be on main thread
        if locationStatus == .notDetermined {
            await MainActor.run {
                self.locationManager.requestWhenInUseAuthorization()
            }
            // Wait for delegate callback
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                self.locationStatus = self.locationManager.authorizationStatus
            }
        }
        
        // Request speech recognition
        if speechStatus == .notDetermined {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    Task { @MainActor in
                        self.speechStatus = status
                        continuation.resume()
                    }
                }
            }
        }
        
        // Request microphone - must be on main thread
        if microphoneStatus == .undetermined {
            await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { _ in
                    continuation.resume()
                }
            }
            await MainActor.run {
                self.microphoneStatus = AVAudioSession.sharedInstance().recordPermission
            }
        }
        
        // Request calendar
        if calendarStatus == .notDetermined {
            let eventStore = EKEventStore()
            let granted = try? await eventStore.requestAccess(to: .event)
            await MainActor.run {
                self.calendarStatus = granted == true ? .authorized : .denied
            }
        }
        
        // Final update of all statuses on main thread
        await MainActor.run {
            self.checkAllPermissions()
        }
    }
    
    var allPermissionsGranted: Bool {
        return cameraStatus == .authorized &&
               (photoLibraryStatus == .authorized || photoLibraryStatus == .limited) &&
               (locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse) &&
               speechStatus == .authorized &&
               (calendarStatus == .fullAccess || calendarStatus == .writeOnly)
    }
    
    var hasDeniedPermissions: Bool {
        return cameraStatus == .denied ||
               photoLibraryStatus == .denied ||
               locationStatus == .denied ||
               speechStatus == .denied ||
               calendarStatus == .denied
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

extension PermissionRequestManager: CLLocationManagerDelegate {
    @MainActor
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.locationStatus = manager.authorizationStatus
    }
}

