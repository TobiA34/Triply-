//
//  ImagePickerView.swift
//  Itinero
//
//  Image picker for selecting trip cover images
//

import SwiftUI
import PhotosUI
import UIKit

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
                        
                        // Simple edit controls: rotate and flip
                        HStack(spacing: 16) {
                            Button {
                                rotateCurrentImage(clockwise: true)
                            } label: {
                                Label("Rotate", systemImage: "rotate.right")
                                    .font(.subheadline.weight(.semibold))
                            }
                            
                            Button {
                                flipCurrentImageHorizontally()
                            } label: {
                                Label("Flip", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("image.selectCover".localized)
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
                        Text(selectedImage == nil ? "image.choosePhoto".localized : "image.changePhoto".localized)
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
                        Text("image.useThisPhoto".localized)
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
            .navigationTitle("image.coverTitle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("common.back".localized)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

// MARK: - Editing helpers
private extension ImagePickerView {
    func rotateCurrentImage(clockwise: Bool) {
        guard let image = selectedImage else { return }
        
        let newSize = CGSize(width: image.size.height, height: image.size.width)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        let rotated = renderer.image { context in
            let cgContext = context.cgContext
            
            if clockwise {
                cgContext.translateBy(x: newSize.width, y: 0)
                cgContext.rotate(by: .pi / 2)
            } else {
                cgContext.translateBy(x: 0, y: newSize.height)
                cgContext.rotate(by: -.pi / 2)
            }
            
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        selectedImage = rotated
    }
    
    func flipCurrentImageHorizontally() {
        guard let image = selectedImage else { return }
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let flipped = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: image.size.width, y: 0)
            cgContext.scaleBy(x: -1, y: 1)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        selectedImage = flipped
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


