//
//  CoolAlertView.swift
//  Itinero
//
//  Modern animated alert system with cool effects
//

import SwiftUI

// MARK: - Alert Manager
@MainActor
class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var currentAlert: AlertItem?
    
    private init() {}
    
    func show(_ alert: AlertItem) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentAlert = alert
        }
        
        // Auto-dismiss after duration
        if alert.duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + alert.duration) {
                self.dismiss()
            }
        }
    }
    
    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentAlert = nil
        }
    }
}

// MARK: - Alert Item
struct AlertItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?
    let icon: String?
    let style: AlertStyle
    let duration: Double
    let action: (() -> Void)?
    
    // Equatable conformance - compare by id since actions can't be compared
    static func == (lhs: AlertItem, rhs: AlertItem) -> Bool {
        lhs.id == rhs.id
    }
    
    enum AlertStyle: Equatable {
        case success
        case error
        case warning
        case info
        case custom(primary: Color, secondary: Color)
    }
    
    init(
        title: String,
        message: String? = nil,
        icon: String? = nil,
        style: AlertStyle = .info,
        duration: Double = 3.0,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.style = style
        self.duration = duration
        self.action = action
    }
}

// MARK: - Cool Alert View
struct CoolAlertView: View {
    @ObservedObject var alertManager = AlertManager.shared
    @State private var dragOffset: CGFloat = 0
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            if let alert = alertManager.currentAlert {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        alertManager.dismiss()
                    }
                    .transition(.opacity)
                
                // Alert card
                VStack(spacing: 0) {
                    // Icon and title section
                    VStack(spacing: 16) {
                        if let icon = alert.icon {
                            ZStack {
                                Circle()
                                    .fill(alert.style.gradient)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: alert.style.primaryColor.opacity(0.4), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce, value: isVisible)
                            }
                            .scaleEffect(isVisible ? 1.0 : 0.3)
                            .rotationEffect(.degrees(isVisible ? 0 : -180))
                        }
                        
                        VStack(spacing: 8) {
                            Text(alert.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            if let message = alert.message {
                                Text(message)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                            }
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Action button
                    if alert.action != nil {
                        Divider()
                        
                        Button(action: {
                            alert.action?()
                            alertManager.dismiss()
                        }) {
                            Text("OK")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(alert.style.primaryColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 20)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [alert.style.primaryColor.opacity(0.3), alert.style.primaryColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .offset(y: dragOffset)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                alertManager.dismiss()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom))
                ))
            }
        }
        .onChange(of: alertManager.currentAlert) { oldValue, newAlert in
            if newAlert != nil {
                isVisible = true
            } else {
                isVisible = false
                dragOffset = 0
            }
        }
    }
}

// MARK: - Alert Style Extensions
extension AlertItem.AlertStyle {
    var primaryColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        case .custom(let primary, _):
            return primary
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .success:
            return .green.opacity(0.7)
        case .error:
            return .red.opacity(0.7)
        case .warning:
            return .orange.opacity(0.7)
        case .info:
            return .blue.opacity(0.7)
        case .custom(_, let secondary):
            return secondary
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [primaryColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var defaultIcon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .custom:
            return "bell.fill"
        }
    }
}

// MARK: - View Extension for Easy Alert Display
extension View {
    func coolAlert() -> some View {
        self.overlay(
            CoolAlertView()
                .allowsHitTesting(true)
        )
    }
}

// MARK: - Convenience Functions
extension AlertManager {
    func showSuccess(_ title: String, message: String? = nil, duration: Double = 2.5) {
        show(AlertItem(
            title: title,
            message: message,
            icon: "checkmark.circle.fill",
            style: .success,
            duration: duration
        ))
    }
    
    func showError(_ title: String, message: String? = nil, duration: Double = 3.0) {
        show(AlertItem(
            title: title,
            message: message,
            icon: "xmark.circle.fill",
            style: .error,
            duration: duration
        ))
    }
    
    func showWarning(_ title: String, message: String? = nil, duration: Double = 3.0) {
        show(AlertItem(
            title: title,
            message: message,
            icon: "exclamationmark.triangle.fill",
            style: .warning,
            duration: duration
        ))
    }
    
    func showInfo(_ title: String, message: String? = nil, duration: Double = 2.5) {
        show(AlertItem(
            title: title,
            message: message,
            icon: "info.circle.fill",
            style: .info,
            duration: duration
        ))
    }
}