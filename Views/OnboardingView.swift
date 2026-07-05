//
//  OnboardingView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let userDefaults = UserDefaults.standard
    private let hasSeenOnboardingKey = "itinero_has_seen_onboarding"
    private let hasSeenPostOnboardingPaywallKey = "itinero_has_seen_post_onboarding_paywall"

    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "airplane.departure",
                title: "Plan Your Trips",
                description: "Organize all your travel plans in one beautiful place"
            ),
            OnboardingPage(
                icon: "map.fill",
                title: "Track Everything",
                description: "Manage destinations, expenses, and itineraries effortlessly"
            ),
            OnboardingPage(
                icon: "creditcard.fill",
                title: "Track Budgets & Expenses",
                description: "Keep tabs on spending and maximize your travel budget"
            ),
            OnboardingPage(
                icon: "sparkles",
                title: "Ready to Start",
                description: "Create your first trip and begin your journey!"
            )
        ]
    }
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        isPresented = false
                        HapticManager.shared.selection()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Next/Get Started button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                        HapticManager.shared.impact(.light)
                    } else {
                        // Mark onboarding as seen and reset post-onboarding paywall flag
                        userDefaults.set(true, forKey: hasSeenOnboardingKey)
                        userDefaults.set(false, forKey: hasSeenPostOnboardingPaywallKey)
                        isPresented = false
                        HapticManager.shared.success()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
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
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.white)
                .scaleEffect(animate ? 1.1 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true), value: animate)
                .onAppear {
                    animate = true
                }
            
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}


