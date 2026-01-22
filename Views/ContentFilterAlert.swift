//
//  ContentFilterAlert.swift
//  Itinero
//
//  Modern alert for blocked content
//

import SwiftUI

struct ContentFilterAlert: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        ZStack {
                            // Background blur
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isPresented = false
                                    }
                                }
                            
                            // Alert card
                            VStack(spacing: 0) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 32, weight: .semibold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.red, Color.orange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .padding(.top, 30)
                                .padding(.bottom, 20)
                                
                                // Title
                                Text("Inappropriate Content")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 8)
                                
                                // Message
                                Text("Your message contains language that doesn't align with our community guidelines. Please revise your text.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 30)
                                    .padding(.bottom, 30)
                                
                                // Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        isPresented = false
                                    }
                                }) {
                                    Text("Got it")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 30)
                            }
                            .frame(width: 320)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            )
                            .scaleEffect(isPresented ? 1.0 : 0.8)
                            .opacity(isPresented ? 1.0 : 0.0)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            )
    }
}

extension View {
    func contentFilterAlert(isPresented: Binding<Bool>) -> some View {
        modifier(ContentFilterAlert(isPresented: isPresented))
    }
}

