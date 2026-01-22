//
//  GlassmorphicCard.swift
//  Itinero
//
//  Reusable glassmorphism card component
//

import SwiftUI

struct GlassmorphicCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20
    var shadowRadius: CGFloat = 10
    var borderOpacity: CGFloat = 0.3
    
    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderOpacity: CGFloat = 0.3,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderOpacity = borderOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(borderOpacity),
                                        Color.white.opacity(borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
            )
    }
}

// ViewModifier for glassmorphic effect
struct GlassmorphicCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20
    var shadowRadius: CGFloat = 10
    var borderOpacity: CGFloat = 0.3
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(borderOpacity),
                                        Color.white.opacity(borderOpacity * 0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 5)
            )
    }
}

// Convenience modifier for easy application
extension View {
    func glassmorphicCard(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderOpacity: CGFloat = 0.3
    ) -> some View {
        modifier(GlassmorphicCardModifier(
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: shadowRadius,
            borderOpacity: borderOpacity
        ))
    }
}

