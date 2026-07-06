//
//  ContentView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var refreshID = UUID()
    @State private var showOnboarding = false
    @State private var showPostOnboardingPaywall = false
    @State private var landingComplete = false
    @State private var landingPhase: LandingPhase = .hidden

    var body: some View {
        ZStack {
            MainTabView()
                .id(refreshID)
                .opacity(landingComplete ? 1 : 0)
                .scaleEffect(landingComplete ? 1 : 0.96)
                .animation(Animation.spring(response: 0.6, dampingFraction: 0.85), value: landingComplete)

            if !landingComplete {
                LandingOverlayView(phase: landingPhase)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.environment["UITesting"] == "true",
               let urlString = ProcessInfo.processInfo.environment["url"],
               let url = URL(string: urlString) {
                handleDeepLink(url)
            }
            let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "has_seen_onboarding")
            let lastSeenVersion = UserDefaults.standard.string(forKey: "last_seen_app_version")
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let isNewVersion = lastSeenVersion != nil && lastSeenVersion != currentVersion
            Task { @MainActor in
                if !hasSeenOnboarding || isNewVersion {
                    showOnboarding = true
                } else {
                    startLandingIfNeeded()
                }
            }
            Task {
                settingsManager.createDefaultSettings(in: modelContext)
                settingsManager.loadSettings(from: modelContext)
            }
        }
        .onChange(of: localizationManager.currentLanguage) { oldValue, newValue in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    refreshID = UUID()
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            // Always persist when the cover goes away (skip, finish, or system dismiss) so
            // What's New / onboarding does not reappear on every launch or after language refresh.
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
            UserDefaults.standard.set(currentVersion, forKey: "last_seen_app_version")
            startLandingIfNeeded()
            // One-time post-onboarding paywall — only when packages actually
            // loaded, so new users never see a configuration error.
            let hasSeenPaywall = UserDefaults.standard.bool(forKey: "itinero_has_seen_post_onboarding_paywall")
            if !hasSeenPaywall && !IAPManager.shared.isPro {
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    if await IAPManager.shared.preparePaywall() {
                        showPostOnboardingPaywall = true
                        UserDefaults.standard.set(true, forKey: "itinero_has_seen_post_onboarding_paywall")
                    }
                }
            }
        }) {
            let lastSeenVersion = UserDefaults.standard.string(forKey: "last_seen_app_version")
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            let isUpdateFlow = lastSeenVersion != nil && lastSeenVersion != currentVersion
            OnboardingView(isPresented: $showOnboarding, isUpdateFlow: isUpdateFlow)
        }
        .sheet(isPresented: $showPostOnboardingPaywall) {
            PaywallView()
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .refreshOnLanguageChange()
    }
    
    /// Handle itinero://trip/{uuid} to open a specific trip.
    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "itinero",
              url.host?.lowercased() == "trip" else { return }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let tripId = UUID(uuidString: path) else { return }
        UserDefaults.standard.set(tripId.uuidString, forKey: "PendingOpenTripId")
        NotificationCenter.default.post(
            name: NSNotification.Name("SwitchToTripsTab"),
            object: nil
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToTrip"),
                object: nil,
                userInfo: ["tripId": tripId.uuidString]
            )
        }
    }

    private func startLandingIfNeeded() {
        guard !landingComplete else { return }
        landingPhase = .visible
        withAnimation(Animation.easeOut(duration: 0.35)) {
            landingPhase = .shown
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(Animation.easeInOut(duration: 0.4)) {
                landingPhase = .hidden
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                landingComplete = true
            }
        }
    }
}

private enum LandingPhase {
    case hidden
    case visible
    case shown
}

// MARK: - Joyful landing (bright travel – independent of app theme)
private struct LandingOverlayView: View {
    let phase: LandingPhase
    @State private var gradientPhase: CGFloat = 0
    @State private var floatPhase: CGFloat = 0
    @State private var iconScale: CGFloat = 0.4
    @State private var iconBounce: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0

    // Fixed joyful palette – cool sky / ocean (matches default blue app theme)
    private static let warmCoral = Color(red: 0.25, green: 0.55, blue: 0.98)
    private static let softPeach = Color(red: 0.55, green: 0.78, blue: 1.0)
    private static let goldenHour = Color(red: 0.45, green: 0.72, blue: 1.0)
    private static let skyBlue = Color(red: 0.35, green: 0.68, blue: 1.0)
    private static let softTeal = Color(red: 0.3, green: 0.75, blue: 0.92)
    private static let cream = Color(red: 0.94, green: 0.97, blue: 1.0)
    private static let warmWhite = Color(red: 1.0, green: 1.0, blue: 1.0)

    var body: some View {
        ZStack {
            joyfulBackground
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                        gradientPhase = 1
                    }
                }

            sunGlow
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        shimmerPhase = 1
                    }
                }

            // Bright, friendly floating travel icons
            LandingFloatingShapes(phase: floatPhase)
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                        floatPhase = 1
                    }
                }

            VStack(spacing: 28) {
                // Hero icon – airplane with warm gradient and gentle bounce
                ZStack {
                    Circle()
                        .fill(Self.softPeach.opacity(0.6))
                        .frame(width: 110, height: 110)
                        .blur(radius: 20)
                        .scaleEffect(phase == .shown ? 1.2 : 0.9)
                    Circle()
                        .fill(Self.warmWhite.opacity(0.9))
                        .frame(width: 88, height: 88)
                        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Self.warmCoral, Self.softPeach],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                        .offset(y: iconBounce * 2)
                }

                Text("app.landing.title".localized)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.2, blue: 0.28),
                                Color(red: 0.25, green: 0.25, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("app.landing.subtitle".localized)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
                    .opacity(phase == .shown ? 1 : 0)
            }
            .scaleEffect(phase == .shown ? 1 : 0.9)
            .opacity(phase == .hidden ? 0 : (phase == .shown ? 1 : 0.4))
            .animation(Animation.spring(response: 0.5, dampingFraction: 0.75), value: phase)
            .onAppear {
                if phase == .shown {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                        iconScale = 1
                    }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        iconBounce = 3
                    }
                }
            }
        }
    }

    private var joyfulBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Self.cream, Self.cream.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [
                    Self.skyBlue.opacity(0.22),
                    Self.softPeach.opacity(0.18),
                    Self.warmCoral.opacity(0.14),
                    Self.softTeal.opacity(0.12),
                    Color.clear
                ],
                startPoint: UnitPoint(x: 0.2 - gradientPhase * 0.2, y: 0),
                endPoint: UnitPoint(x: 0.8 + gradientPhase * 0.2, y: 1.0)
            )
            LinearGradient(
                colors: [Self.goldenHour.opacity(0.2), Color.clear],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.5)
            )
        }
    }

    private var sunGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Self.skyBlue.opacity(0.3),
                        Self.softPeach.opacity(0.12),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 120
                )
            )
            .frame(width: 240, height: 240)
            .scaleEffect(0.9 + shimmerPhase * 0.2)
            .offset(y: -180)
    }
}

private struct LandingFloatingShapes: View {
    let phase: CGFloat

    private static let colors: [Color] = [
        Color(red: 0.25, green: 0.55, blue: 0.98),
        Color(red: 0.35, green: 0.75, blue: 0.95),
        Color(red: 0.45, green: 0.65, blue: 1.0),
        Color(red: 0.3, green: 0.8, blue: 0.88),
        Color(red: 0.5, green: 0.6, blue: 1.0),
        Color(red: 0.2, green: 0.45, blue: 0.85),
    ]
    private static let icons = ["airplane", "globe.americas.fill", "mappin.circle.fill", "sun.max.fill", "leaf.fill", "star.fill"]
    private static let positions: [(CGFloat, CGFloat)] = [(0.12, 0.18), (0.88, 0.22), (0.25, 0.62), (0.78, 0.68), (0.08, 0.75), (0.92, 0.55)]
    private static let sizes: [CGFloat] = [28, 22, 24, 26, 20, 24]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    let (px, py) = Self.positions[i]
                    let yOffset = phase * (i % 2 == 0 ? 8 : -8)
                    Image(systemName: Self.icons[i])
                        .font(.system(size: Self.sizes[i], weight: .medium))
                        .foregroundStyle(Self.colors[i].opacity(0.7))
                        .offset(y: yOffset)
                        .position(x: geo.size.width * px, y: geo.size.height * py)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, ItineraryItem.self, AppSettings.self], inMemory: true)
}

