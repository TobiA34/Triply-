//
//  SwiftUIView.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 8/14/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import SwiftUI
import Foundation

// Local content filter helper for WishKit
private func containsBlockedContent(_ text: String) -> Bool {
    let lowercased = text.lowercased()
    let blockedTerms: Set<String> = [
        "fuck", "fucking", "fucked", "fucker", "fuckers",
        "shit", "shitting", "shitted", "shitter",
        "damn", "damned", "dammit",
        "hell", "hells",
        "ass", "asses", "asshole", "assholes",
        "bitch", "bitches", "bitching",
        "bastard", "bastards",
        "crap", "crappy",
        "piss", "pissing", "pissed",
        "dick", "dicks", "dickhead",
        "cock", "cocks",
        "pussy", "pussies",
        "tits", "tit",
        "whore", "whores",
        "slut", "sluts",
        "cunt", "cunts",
        "fag", "fags", "faggot", "faggots", "faggy",
        "homo", "homos",
        "dyke", "dykes",
        "lesbo", "lesbos",
        "nigger", "niggers", "nigga", "niggas", "niggaz",
        "chink", "chinks",
        "gook", "gooks",
        "kike", "kikes",
        "spic", "spics",
        "wetback", "wetbacks",
        "towelhead", "towelheads",
        "sandnigger", "sandniggers",
        "paki", "pakis",
        "jap", "japs",
        "muzzie", "muzzies",
        "raghead", "ragheads",
        "cameljockey", "cameljockeys",
        "tranny", "trannies", "trannys",
        "shemale", "shemales",
        "ladyboy", "ladyboys",
        "retard", "retarded", "retards",
        "retardation",
        "spastic", "spastics",
        "mongoloid", "mongoloids",
        "cripple", "cripples",
        "gimp", "gimps",
        "midget", "midgets"
    ]
    
    let words = lowercased.components(separatedBy: CharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }
    
    for word in words {
        if blockedTerms.contains(word) {
            return true
        }
    }
    
    for term in blockedTerms {
        if lowercased.contains(term) {
            return true
        }
    }
    
    return false
}

struct CommentFieldView: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Binding
    private var textFieldValue: String

    @Binding
    private var isLoading: Bool
    
    @State
    private var showContentFilterAlert = false

    private let submitAction: () async throws -> ()

    init(
        _ textFieldValue: Binding<String>,
        isLoading: Binding<Bool>,
        submitAction: @escaping () async throws -> ()
    ) {
        self._textFieldValue = textFieldValue
        self._isLoading = isLoading
        self.submitAction = submitAction
    }

    var body: some View {
        ZStack {
            TextField(WishKit.config.localization.writeAComment, text: $textFieldValue)
                .textFieldStyle(.plain)
                .font(.footnote)
                .padding([.top, .leading, .bottom], 15)
                .padding([.trailing], 40)
                .foregroundColor(textColor)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: textFieldValue) { oldValue, newValue in
                    if containsBlockedContent(newValue) {
                        textFieldValue = oldValue
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showContentFilterAlert = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showContentFilterAlert = false
                            }
                        }
                    }
                }

            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSizeCompat(.small)
                        .padding(10)
                } else {
                    Button(action: { Task { try await submitAction() } }) {
                        Image(systemName: "paperplane.fill")
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(WishKit.theme.primaryColor)
                    .disabled(textFieldValue.replacingOccurrences(of: " ", with: "").isEmpty)
                }
            }
        }
        .overlay(
            Group {
                if showContentFilterAlert {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showContentFilterAlert = false
                                }
                            }
                        
                        VStack(spacing: 0) {
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
                            
                            Text("Inappropriate Content")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                            
                            Text("Your message contains language that doesn't align with our community guidelines. Please revise your text.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 30)
                                .padding(.bottom, 30)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showContentFilterAlert = false
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
                        .scaleEffect(showContentFilterAlert ? 1.0 : 0.8)
                        .opacity(showContentFilterAlert ? 1.0 : 0.0)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
}

extension CommentFieldView {

    var textColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        case .dark:
            if let color = WishKit.theme.textColor {
                return color.dark
            }

            return .white
        @unknown default:
            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        }
    }

    var backgroundColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.secondaryColor {
                return color.dark
            }

            return PrivateTheme.elementBackgroundColor.dark
        @unknown default:
            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        }
    }
}
