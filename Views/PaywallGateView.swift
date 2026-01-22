//
//  PaywallGateView.swift
//  Itinero
//
//  Created on 2025
//

import SwiftUI

struct PaywallGateView: View {
    let featureName: String
    let featureDescription: String
    let icon: String
    let iconColor: Color
    @State private var showPaywall = false
    @State private var showFeatures = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
                .padding(.top, 8)
            
            Text(featureName)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.center)
            
            Text(featureDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            
            VStack(spacing: 12) {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Pro")
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                
                Button {
                    showFeatures = true
                } label: {
                    Text("View All Pro Features")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .sheet(isPresented: $showFeatures) {
            NavigationStack {
                ProFeaturesView()
            }
        }
    }
}

#Preview {
    PaywallGateView(
        featureName: "AI Chat Assistant",
        featureDescription: "Have natural conversations with your AI travel assistant",
        icon: "message.fill",
        iconColor: .blue
    )
}


