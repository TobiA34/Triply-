//
//  AnimationComponents.swift
//  Itinero
//
//  Cool animation components for enhanced UX
//

import SwiftUI

// MARK: - Loading Skeleton
struct LoadingSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray6),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Trip Card Skeleton
struct TripCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header skeleton
            LoadingSkeleton()
                .frame(height: 140)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 20,
                            bottomLeading: 0,
                            bottomTrailing: 0,
                            topTrailing: 20
                        )
                    )
                )
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(spacing: 8) {
                            LoadingSkeleton()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            
                            VStack(spacing: 4) {
                                LoadingSkeleton()
                                    .frame(width: 40, height: 18)
                                LoadingSkeleton()
                                    .frame(width: 30, height: 12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        if index < 2 {
                            Divider()
                                .frame(height: 40)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Color(.systemBackground)
                    .clipShape(
                        UnevenRoundedRectangle(
                            cornerRadii: .init(
                                topLeading: 0,
                                bottomLeading: 20,
                                bottomTrailing: 20,
                                topTrailing: 0
                            )
                        )
                    )
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Animated Button
struct AnimatedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: Color.blue.opacity(0.3), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Success Checkmark Animation
struct SuccessCheckmark: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
        }
    }
}

// MARK: - Shake Animation
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * CGFloat.pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func shake(times: Int) -> some View {
        modifier(ShakeModifier(shakes: times))
    }
}

struct ShakeModifier: ViewModifier {
    let shakes: Int
    @State private var animatableShakes: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: animatableShakes))
            .onAppear {
                if shakes > 0 {
                    withAnimation(.default) {
                        animatableShakes = CGFloat(shakes)
                    }
                }
            }
            .id(shakes) // Force view update when shakes changes
    }
}

// MARK: - Ripple Effect
struct RippleEffect: ViewModifier {
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0.6
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(Color.white.opacity(rippleOpacity))
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
            )
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.6)) {
                    rippleScale = 2.0
                    rippleOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    rippleScale = 0
                    rippleOpacity = 0.6
                }
            }
    }
}

extension View {
    func ripple() -> some View {
        modifier(RippleEffect())
    }
}

// MARK: - Staggered Animation Modifier
struct StaggeredAnimation: ViewModifier {
    let index: Int
    let delay: Double
    
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay * Double(index))) {
                    opacity = 1.0
                    offset = 0
                }
            }
    }
}

extension View {
    func staggered(index: Int, delay: Double = 0.1) -> some View {
        modifier(StaggeredAnimation(index: index, delay: delay))
    }
}

// MARK: - Pull to Refresh
struct PullToRefresh: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                VStack {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: "arrow.down")
                            .rotationEffect(.degrees(geometry.frame(in: .global).minY > 100 ? 180 : 0))
                            .animation(.easeInOut, value: geometry.frame(in: .global).minY)
                    }
                }
                .frame(maxWidth: .infinity)
                .opacity(min(1.0, Double(geometry.frame(in: .global).minY - 50) / 50.0))
            }
        }
        .frame(height: 50)
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @Binding var trigger: Bool
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var position: CGPoint
        var rotation: Double
        var color: Color
        var size: CGFloat
        var finalX: CGFloat
        var finalY: CGFloat
        var finalRotation: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { oldValue, newValue in
            if newValue && !oldValue {
                startConfetti()
            }
        }
    }
    
    private func startConfetti() {
        confettiPieces = []
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2
        
        for i in 0..<50 {
            let angle = Double(i) * (2 * .pi / 50)
            let velocity: CGFloat = 200 + CGFloat.random(in: 0...100)
            let x = cos(angle) * velocity
            let y = sin(angle) * velocity
            
            let piece = ConfettiPiece(
                position: CGPoint(x: centerX, y: centerY),
                rotation: Double.random(in: 0...360),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 8...16),
                finalX: centerX + x,
                finalY: centerY + y - 100,
                finalRotation: Double.random(in: 360...720)
            )
            
            confettiPieces.append(piece)
        }
        
        // Animate all pieces
        for i in 0..<confettiPieces.count {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(i) * 0.01)) {
                confettiPieces[i].position = CGPoint(
                    x: confettiPieces[i].finalX,
                    y: confettiPieces[i].finalY
                )
                confettiPieces[i].rotation = confettiPieces[i].finalRotation
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            confettiPieces = []
            trigger = false
        }
    }
}

// MARK: - Completion Celebration View
struct CompletionCelebrationView: View {
    @State private var showConfetti = false
    @State private var showCheckmark = false
    @State private var scale: CGFloat = 0
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView(trigger: $showConfetti)
            }
            
            if showCheckmark {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)
                        .opacity(scale > 0 ? 1 : 0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .opacity(scale > 0 ? 1 : 0)
                }
            }
        }
        .onAppear {
            showCheckmark = true
            showConfetti = true
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            HapticManager.shared.success()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    scale = 0
                    showCheckmark = false
                    showConfetti = false
                }
            }
        }
    }
}

