//
//  TripHeroImageView.swift
//  Itinero
//
//  Hero image view with parallax effect for trip details
//

import SwiftUI
import UIKit

struct TripHeroImageView: View {
    let image: UIImage?
    let tripName: String
    let category: String
    let dateRange: String
    let duration: Int
    let budget: Double?
    @Binding var scrollOffset: CGFloat
    @State private var shimmerOffset: CGFloat = -200
    @State private var particleOffset: CGFloat = 0

    init(
        image: UIImage?,
        tripName: String,
        category: String,
        dateRange: String,
        duration: Int,
        budget: Double?,
        scrollOffset: Binding<CGFloat>
    ) {
        self.image = image
        self.tripName = tripName
        self.category = category
        self.dateRange = dateRange
        self.duration = duration
        self.budget = budget
        self._scrollOffset = scrollOffset
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background Image with Parallax - fills entire area completely
                if let image = image {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width + 40, height: max(geometry.size.height + 600, 800))
                            .contentShape(Rectangle())
                            .offset(x: -20, y: scrollOffset * 0.3 - 300)
                            .clipped()
                            .ignoresSafeArea(edges: .top)
                        
                        // Animated shimmer effect
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset, y: 0)
                        .blur(radius: 20)
                        .onAppear {
                            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                                shimmerOffset = geometry.size.width + 200
                            }
                        }
                    }
                    .overlay(
                        // Enhanced gradient overlay with multiple stops
                        ZStack {
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.0),
                                    Color.black.opacity(0.2),
                                    Color.black.opacity(0.5),
                                    Color.black.opacity(0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            
                            // Radial gradient for depth
                            RadialGradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.3)
                                ],
                                center: .topTrailing,
                                startRadius: 50,
                                endRadius: 200
                            )
                        }
                    )
                } else {
                    // Default gradient background when no image - fills entire area
                    ZStack {
                        LinearGradient(
                            colors: gradientColors(for: category),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geometry.size.width, height: max(geometry.size.height + 400, 600))
                        .ignoresSafeArea(edges: .top)
                        
                        // Animated particles for gradient backgrounds
                        ForEach(0..<5, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: CGFloat.random(in: 20...40))
                                .offset(
                                    x: CGFloat(index) * geometry.size.width / 5 + particleOffset,
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .blur(radius: 10)
                        }
                    }
                    .onAppear {
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            particleOffset = geometry.size.width
                        }
                    }
                }
                
                // Decorative floating icons
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: iconForCategory(category))
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.1))
                            .offset(x: 20, y: -20)
                            .rotationEffect(.degrees(15))
                    }
                    Spacer()
                }
                .padding(.top, 40)
                
                // Content overlay - Enhanced design
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Enhanced trip info card with gradient border - extends to bottom edge
                    VStack(alignment: .leading, spacing: 14) {
                        // Title and category row
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tripName)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Category and date row
                            HStack(spacing: 10) {
                                HeroCategoryBadge(category: category)
                                
                                Label(dateRange, systemImage: "calendar")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.95))
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        
                        // Duration pill
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            Text("tripHeroImageView.durationDaysFormat".localized(duration))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                            let badge = durationDescription(for: duration)
                            if !badge.isEmpty {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text(badge)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                            
                            // Gradient border effect
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        }
                        .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, -30)
                }
            }
        }
        .frame(height: 250)
        .background(
            // Fill background completely - extends beyond frame to cover rounded corners
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width + 40, height: 400)
                        .offset(x: -20, y: -75)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: gradientColors(for: category),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .clipped()
        .ignoresSafeArea(edges: .top)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "adventure":
            return "mountain.2.fill"
        case "business":
            return "briefcase.fill"
        case "leisure", "vacation":
            return "beach.umbrella.fill"
        default:
            return "airplane.departure"
        }
    }
    
    private func gradientColors(for category: String) -> [Color] {
        switch category.lowercased() {
        case "business":
            return [Color(red: 0.35, green: 0.55, blue: 0.95), Color(red: 0.5, green: 0.65, blue: 1.0)]
        case "relaxation", "vacation", "leisure":
            return [Color(red: 1.0, green: 0.65, blue: 0.45), Color(red: 1.0, green: 0.5, blue: 0.6)]
        case "adventure":
            return [Color(red: 0.25, green: 0.75, blue: 0.55), Color(red: 0.4, green: 0.8, blue: 0.65)]
        case "family":
            return [Color(red: 1.0, green: 0.55, blue: 0.7), Color(red: 0.95, green: 0.5, blue: 0.85)]
        default:
            return [Color(red: 0.95, green: 0.5, blue: 0.35), Color(red: 1.0, green: 0.65, blue: 0.45)]
        }
    }
    
    private func durationDescription(for days: Int) -> String {
        switch days {
        case 1: return "trips.durationOneDay".localized
        case 2...3: return "trips.durationShortGetaway".localized
        case 4...6: return "trips.durationNearlyWeek".localized
        case 7: return "trips.durationOneWeek".localized
        case 8...10: return "trips.durationWeekAndBit".localized
        case 11...14: return "trips.durationTwoWeeks".localized
        case 15...21: return "trips.durationAboutThreeWeeks".localized
        default:
            return days % 7 == 0 ? "trips.weeks".localized(days / 7) : "trips.daysTotal".localized(days)
        }
    }
}

// Private CategoryBadge for hero view (glassmorphic style)
private struct HeroCategoryBadge: View {
    let category: String
    
    private var localizedCategory: String {
        switch category.lowercased() {
        case "general": return "category.general".localized
        case "adventure": return "category.adventure".localized
        case "business": return "category.business".localized
        case "relaxation": return "category.relaxation".localized
        case "family": return "category.family".localized
        case "romantic": return "category.romantic".localized
        case "solo": return "category.solo".localized
        case "group": return "category.group".localized
        default: return category
        }
    }
    
    var body: some View {
        Text(localizedCategory)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

