//
//  PermissionRequestView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI
import AVFoundation
import Photos
import CoreLocation
import Speech
import EventKit

struct PermissionRequestView: View {
    @StateObject private var permissionManager = PermissionRequestManager.shared
    @State private var isRequesting = false
    @State private var currentStep = 0
    
    let onComplete: () -> Void
    
    private let permissions: [PermissionItem] = [
        PermissionItem(
            icon: "camera.fill",
            title: "Camera Access",
            description: "Take photos of tickets, receipts, and travel documents",
            color: .blue
        ),
        PermissionItem(
            icon: "photo.on.rectangle",
            title: "Photo Library",
            description: "Select and save travel documents from your photos",
            color: .purple
        ),
        PermissionItem(
            icon: "location.fill",
            title: "Location Services",
            description: "Show trip destinations on maps and provide location-based features",
            color: .green
        ),
        PermissionItem(
            icon: "mic.fill",
            title: "Microphone & Speech",
            description: "Record voice notes and convert them to text",
            color: .orange
        ),
        PermissionItem(
            icon: "calendar",
            title: "Calendar Access",
            description: "Add your trip itinerary and events to your calendar",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Welcome to Itinero!")
                        .font(.largeTitle)
                        .foregroundColor(.primary)
                        .fontWeight(.bold)
                    
                    Text("We need a few permissions to provide the best travel planning experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Permission list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(permissions.indices, id: \.self) { index in
                            PermissionRow(
                                item: permissions[index],
                                status: getStatus(for: index)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Requesting permissions...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button {
                            Task { @MainActor in
                                isRequesting = true
                                
                                // Request permissions
                                await permissionManager.requestAllPermissions()
                                
                                // Wait a moment for UI to update
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                
                                isRequesting = false
                                onComplete()
                            }
                        } label: {
                            Text("Grant All Permissions")
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
                        
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip for Now")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            permissionManager.checkAllPermissions()
        }
    }
    
    private func getStatus(for index: Int) -> PermissionStatus {
        switch index {
        case 0: // Camera
            switch permissionManager.cameraStatus {
            case .authorized: return .granted
            case .denied, .restricted: return .denied
            default: return .notDetermined
            }
        case 1: // Photo Library
            switch permissionManager.photoLibraryStatus {
            case .authorized, .limited: return .granted
            case .denied, .restricted: return .denied
            default: return .notDetermined
            }
        case 2: // Location
            switch permissionManager.locationStatus {
            case .authorizedWhenInUse, .authorizedAlways: return .granted
            case .denied, .restricted: return .denied
            default: return .notDetermined
            }
        case 3: // Speech
            switch permissionManager.speechStatus {
            case .authorized: return .granted
            case .denied, .restricted: return .denied
            default: return .notDetermined
            }
        case 4: // Calendar
            switch permissionManager.calendarStatus {
            case .authorized: return .granted
            case .denied, .restricted: return .denied
            default: return .notDetermined
            }
        default:
            return .notDetermined
        }
    }
}

struct PermissionItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

struct PermissionRow: View {
    let item: PermissionItem
    let status: PermissionStatus
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundColor(item.color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            Group {
                switch status {
                case .granted:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .denied:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                case .notDetermined:
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .font(.title3)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

