//
//  DestinationPhotoGallery.swift
//  Itinero
//
//  Photo gallery for destinations
//

import SwiftUI
import SwiftData

struct DestinationPhotoGallery: View {
    let destination: DestinationModel
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingFullScreen = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Add Photo Button
                Button {
                    showingImagePicker = true
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Photo Grid
                ForEach(0..<5, id: \.self) { index in
                    // Placeholder for photos
                    // In production, load from destination.photos array
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .onTapGesture {
                            showingFullScreen = true
                        }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { image in
                selectedImage = image
                // Save to destination
                // destination.photos.append(image)
            }
        }
    }
}



