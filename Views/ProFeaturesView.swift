//
//  ProFeaturesView.swift
//  Itinero
//
//  Comprehensive Pro Features View with Game-Changing Features
//

import SwiftUI

// Shared enum for premium features
enum PremiumFeature {
    case aiGeneration
    case socialImport
    case routeOptimization
    case offline
    case export
    case packing
}

struct ProFeaturesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var iapManager = IAPManager.shared
    @State private var showPaywall = false
    var highlightedFeature: PremiumFeature? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Itinero Pro")
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("Turn your saved posts into amazing trips")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Game-Changing Features Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Game-Changing Features")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    // AI Itinerary Generation
                    DetailedPremiumFeatureCard(
                        icon: "sparkles.rectangle.stack",
                        iconColor: .purple,
                        title: "AI Itinerary Generation",
                        description: "Automatically create complete day-by-day itineraries from your destinations. Just add destinations and let AI plan your perfect trip.",
                        features: [
                            "Smart day-by-day planning",
                            "Automatic activity suggestions",
                            "Time-optimized schedules",
                            "Weather-aware recommendations"
                        ],
                        isHighlighted: highlightedFeature == .aiGeneration
                    )
                    
                    // Social Media Import
                    DetailedPremiumFeatureCard(
                        icon: "square.and.arrow.down.on.square",
                        iconColor: .pink,
                        title: "Social Media Import",
                        description: "Import saved posts from Instagram and Pinterest. Turn your saved posts into trip destinations instantly.",
                        features: [
                            "Import from Instagram saved posts",
                            "Import from Pinterest boards",
                            "Auto-extract locations and photos",
                            "One-tap destination creation"
                        ],
                        isHighlighted: highlightedFeature == .socialImport
                    )
                    
                    // Advanced Route Optimization
                    DetailedPremiumFeatureCard(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .blue,
                        title: "Smart Route Optimization",
                        description: "One-tap optimization for the shortest travel time between activities. Save hours of planning time.",
                        features: [
                            "One-tap route optimization",
                            "Distance-based sorting",
                            "Travel time calculations",
                            "Efficient day planning"
                        ],
                        isHighlighted: highlightedFeature == .routeOptimization
                    )
                    
                    // Offline Access
                    DetailedPremiumFeatureCard(
                        icon: "icloud.slash",
                        iconColor: .teal,
                        title: "Offline Access",
                        description: "Download trips and access them anywhere, even without internet. Perfect for international travel.",
                        features: [
                            "Download trips for offline use",
                            "Access maps and directions offline",
                            "View itineraries without internet",
                            "Perfect for international travel"
                        ],
                        isHighlighted: highlightedFeature == .offline
                    )
                    
                    // Advanced Export
                    DetailedPremiumFeatureCard(
                        icon: "square.and.arrow.up",
                        iconColor: .orange,
                        title: "Advanced Export",
                        description: "Export your trips in multiple formats. Share with friends, add to calendar, or print as PDF.",
                        features: [
                            "Export to PDF",
                            "Add to Calendar",
                            "Share with friends",
                            "Print-friendly formats"
                        ],
                        isHighlighted: highlightedFeature == .export
                    )
                    
                    // Smart Packing Suggestions
                    DetailedPremiumFeatureCard(
                        icon: "suitcase",
                        iconColor: .indigo,
                        title: "Smart Packing Suggestions",
                        description: "AI-powered packing suggestions based on weather, destination, and trip duration.",
                        features: [
                            "Weather-based suggestions",
                            "Destination-specific items",
                            "Trip duration awareness",
                            "Smart category organization"
                        ],
                        isHighlighted: highlightedFeature == .packing
                    )
                }
                .padding(.horizontal)
                
                // Unlimited Features Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Plus Unlimited Access")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        FeatureCard(
                            icon: "airplane",
                            iconColor: .blue,
                            title: "Unlimited Trips",
                            description: "Plan as many trips as you want. Free users can create up to 3 trips.",
                            features: [
                                "No trip limit",
                                "Plan multiple trips simultaneously",
                                "Organize all your travels"
                            ]
                        )
                        
                        FeatureCard(
                            icon: "mappin.circle",
                            iconColor: .red,
                            title: "Unlimited Destinations",
                            description: "Add as many destinations as you need. Free users can add up to 5 destinations per trip.",
                            features: [
                                "No destination limit",
                                "Plan complex multi-city trips",
                                "Add all your stops"
                            ]
                        )
                        
                        FeatureCard(
                            icon: "calendar",
                            iconColor: .orange,
                            title: "Unlimited Activities",
                            description: "Add unlimited activities to your itinerary. Free users can add up to 10 activities per day.",
                            features: [
                                "No activity limit",
                                "Plan detailed day-by-day schedules",
                                "Add all your plans"
                            ]
                        )
                        
                        FeatureCard(
                            icon: "creditcard",
                            iconColor: .green,
                            title: "Unlimited Expenses",
                            description: "Track every expense without limits. Free users can add up to 20 expenses per trip.",
                            features: [
                                "No expense limit",
                                "Track all your spending",
                                "Complete budget management"
                            ]
                        )
                        
                        FeatureCard(
                            icon: "doc.text",
                            iconColor: .teal,
                            title: "Unlimited Documents",
                            description: "Store all your travel documents. Free users can add up to 10 documents per trip.",
                            features: [
                                "No document limit",
                                "Keep all receipts and tickets",
                                "Organize everything"
                            ]
                        )
                    }
                }
                .padding(.horizontal)
                
                // Upgrade Button
                VStack(spacing: 16) {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade to Pro")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    
                    if let proProduct = iapManager.products.first {
                        Text(proProduct.displayPrice)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Cancel anytime • Auto-renewable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Pro Features")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .task {
            await iapManager.loadProducts()
        }
    }
}

// MARK: - Premium Feature Card (Game-Changing Features)
struct DetailedPremiumFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
    let isHighlighted: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.headline)
                
                if isHighlighted {
                    Spacer()
                    Text("Featured")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(iconColor)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 62)
        }
        .padding()
        .background(
            Group {
                if isHighlighted {
                    LinearGradient(
                        colors: [iconColor.opacity(0.1), iconColor.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color(.systemBackground)
                }
            }
        )
        .cornerRadius(16)
        .shadow(color: isHighlighted ? iconColor.opacity(0.2) : .black.opacity(0.05), radius: isHighlighted ? 12 : 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? iconColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Feature Card (Unlimited Features)
struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(10)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(iconColor)
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.leading, 52)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        ProFeaturesView()
    }
}
