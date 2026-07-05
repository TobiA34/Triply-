//
//  OnboardingView.swift
//  Itinero
//
//  Created on 2024
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    var isUpdateFlow: Bool = false
    var onComplete: (() -> Void)? = nil
    @State private var currentPage = 0
    
    private static var whatsNewPage: OnboardingPage {
        OnboardingPage(
            icon: "sparkles",
            title: "onboarding.whatsNew.title".localized,
            description: "onboarding.whatsNew.subtitle".localized,
            items: [
                "onboarding.whatsNew.item1".localized,
                "onboarding.whatsNew.item2".localized,
                "onboarding.whatsNew.item3".localized,
                "onboarding.whatsNew.item4".localized
            ]
        )
    }
    
    var pages: [OnboardingPage] {
        if isUpdateFlow {
            return [
                Self.whatsNewPage,
                OnboardingPage(
                    icon: "checkmark.circle.fill",
                    title: "onboarding.whatsNew.continueTitle".localized,
                    description: "onboarding.whatsNew.continueDesc".localized
                )
            ]
        }
        return [
            Self.whatsNewPage,
            OnboardingPage(
                icon: "airplane.departure",
                title: "onboarding.planTrips".localized,
                description: "onboarding.planTripsDesc".localized
            ),
            OnboardingPage(
                icon: "map.fill",
                title: "onboarding.trackEverything".localized,
                description: "onboarding.trackEverythingDesc".localized
            ),
            OnboardingPage(
                icon: "brain.head.profile",
                title: "onboarding.aiInsights".localized,
                description: "onboarding.aiInsightsDesc".localized
            ),
            OnboardingPage(
                icon: "crown.fill",
                title: "onboarding.proTitle".localized,
                description: "onboarding.proDesc".localized,
                testimonial: OnboardingTestimonial(
                    quote: "onboarding.proTestimonialQuote".localized,
                    authorName: "onboarding.proTestimonialAuthor".localized,
                    authorRole: "onboarding.proTestimonialRole".localized
                )
            ),
            OnboardingPage(
                icon: "sparkles",
                title: "onboarding.readyToStart".localized,
                description: "onboarding.readyToStartDesc".localized
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
                    Button("onboarding.skip".localized) {
                        onComplete?()
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
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                        HapticManager.shared.impact(.light)
                    } else {
                        onComplete?()
                        isPresented = false
                        HapticManager.shared.success()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "common.next".localized : (isUpdateFlow ? "onboarding.whatsNew.continue".localized : "onboarding.getStarted".localized))
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
                .buttonStyle(OnboardingButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingTestimonial {
    let quote: String
    let authorName: String
    let authorRole: String
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    var testimonial: OnboardingTestimonial? = nil
    var items: [String]? = nil
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animate = false
    @State private var contentAppeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: page.testimonial != nil ? 56 : 80))
                .foregroundStyle(
                    page.testimonial != nil
                        ? LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.white, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .scaleEffect(animate && page.testimonial != nil ? 1.05 : (contentAppeared ? 1.0 : 0.7))
                .opacity(contentAppeared ? 1 : 0)
                .animation(page.testimonial == nil ? .spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true) : .default, value: animate)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: contentAppeared)
                .onAppear {
                    contentAppeared = true
                    animate = true
                }
            
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 15)
            
            if let testimonial = page.testimonial {
                VStack(spacing: 16) {
                    Text(testimonial.quote)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .italic()
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 8)
                    
                    VStack(spacing: 2) {
                        Text("— \(testimonial.authorName)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(testimonial.authorRole)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(contentAppeared ? 1 : 0)
                }
                .padding(.horizontal, 20)
            } else if let items = page.items, !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(page.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 28)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 10)
            } else {
                Text(page.description)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 10)
            }
            
            if page.testimonial != nil {
                Text(page.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(contentAppeared ? 1 : 0)
            }
            
            Spacer()
        }
    }
}

private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Animation.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}


