//
//  ScanningAnimationView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI

struct ScanningAnimationView: View {
    @State private var scanningLineOffset: CGFloat = -200
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Scanning line - wider and more visible
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.blue.opacity(0.4),
                        Color.blue.opacity(0.9),
                        Color.cyan.opacity(0.9),
                        Color.blue.opacity(0.9),
                        Color.blue.opacity(0.4),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 150)
                .offset(x: scanningLineOffset)
                .blur(radius: 1)
                .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // Corner brackets
                VStack {
                    HStack {
                        // Top-left corner - thicker and more visible
                        VStack(alignment: .leading, spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 4)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 40)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                        }
                        Spacer()
                        // Top-right corner
                        VStack(alignment: .trailing, spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 4)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 40)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                        }
                    }
                    Spacer()
                    HStack {
                        // Bottom-left corner
                        VStack(alignment: .leading, spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 40)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 4)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                        }
                        Spacer()
                        // Bottom-right corner
                        VStack(alignment: .trailing, spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 40)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 4)
                                .shadow(color: .blue.opacity(0.8), radius: 5)
                        }
                    }
                }
                .padding(8)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        // Reset to start position
        scanningLineOffset = -200
        // Animate much slower - 6 seconds per pass for better visibility
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            scanningLineOffset = 400
        }
    }
}

// Scanning overlay for images
struct ScanningOverlay: View {
    @Binding var isScanning: Bool
    
    var body: some View {
        ZStack {
            if isScanning {
                ScanningAnimationView()
                    .allowsHitTesting(false)
                
                // Pulsing dots - larger and slower
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .scaleEffect(isScanning ? 1.3 : 0.7)
                            .opacity(isScanning ? 1.0 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever()
                                    .delay(Double(index) * 0.3),
                                value: isScanning
                            )
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

