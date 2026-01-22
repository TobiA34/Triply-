//
//  ImagePickerView.swift
//  Itinero
//
//  Image picker for selecting trip cover images
//

import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    let onImageSelected: (UIImage) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 350)
                        .cornerRadius(16)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Select a cover image for your trip")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                }
                
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text(selectedImage == nil ? "Choose Photo" : "Change Photo")
                            .fontWeight(.semibold)
                    }
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
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                        }
                    }
                }
                
                if selectedImage != nil {
                    Button {
                        if let image = selectedImage {
                            onImageSelected(image)
                            dismiss()
                        }
                    } label: {
                        Text("Use This Photo")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Cover Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}


//  Itinero
//
//  Image picker for selecting trip cover images
//

import SwiftUI
import PhotosUI



//  Itinero
//
//  Image picker for selecting trip cover images
//

import SwiftUI
import PhotosUI



//  Itinero
//
//  Image picker for selecting trip cover images
//

import SwiftUI
import PhotosUI


