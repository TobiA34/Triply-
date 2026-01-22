//
//  CreateWishView.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 8/26/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import SwiftUI
import Combine
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

struct CreateWishView: View {

    @Environment(\.presentationMode)
    var presentationMode

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    private var alertModel = AlertModel()

    @State
    private var titleCharCount = 0

    @State
    private var titleText = ""

    @State
    private var emailText = ""

    @State
    private var descriptionText = ""

    @State
    private var isButtonDisabled = true

    @State
    private var isButtonLoading: Bool? = false

    @State
    private var showConfirmationAlert = false
    
    @State
    private var showContentFilterAlert = false

    let createActionCompletion: () -> Void

    var closeAction: (() -> Void)? = nil

    var saveButtonSize: CGSize {
        #if os(macOS) || os(visionOS)
            return CGSize(width: 100, height: 30)
        #else
            return CGSize(width: 200, height: 45)
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            if showCloseButton() {
                HStack {
                    Spacer()
                    CloseButton(closeAction: dismissViewAction)
                        .alert(isPresented: $showConfirmationAlert) {
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok), action: crossPlatformDismiss)
                            
                            return Alert(
                                title: Text(WishKit.config.localization.info),
                                message: Text(WishKit.config.localization.discardEnteredInformation),
                                primaryButton: button,
                                secondaryButton: .cancel()
                            )
                        }
                }
            }

            ScrollView {
                VStack(spacing: 15) {
                    VStack(spacing: 0) {
                        HStack {
                            Text(WishKit.config.localization.title)
                            Spacer()
                            Text("\(titleText.count)/50")
                        }
                        .font(.caption2)
                        .padding([.leading, .trailing, .bottom], 5)

                        TextField("", text: $titleText)
                            .padding(10)
                            .textFieldStyle(.plain)
                            .foregroundColor(textColor)
                            .background(fieldBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                            .onReceive(Just(titleText)) { _ in handleTitleAndDescriptionChange() }
                            .onChange(of: titleText) { oldValue, newValue in
                                if containsBlockedContent(newValue) {
                                    titleText = oldValue
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
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Text(WishKit.config.localization.description)
                            Spacer()
                            Text("\(descriptionText.count)/500")
                        }
                        .font(.caption2)
                        .padding([.leading, .trailing, .bottom], 5)

                        TextEditor(text: $descriptionText)
                            .padding([.leading, .trailing], 5)
                            .padding([.top, .bottom], 10)
                            .lineSpacing(3)
                            .frame(height: 200)
                            .foregroundColor(textColor)
                            .scrollContentBackgroundCompat(.hidden)
                            .background(fieldBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                            .onReceive(Just(descriptionText)) { _ in handleTitleAndDescriptionChange() }
                            .onChange(of: descriptionText) { oldValue, newValue in
                                if containsBlockedContent(newValue) {
                                    descriptionText = oldValue
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
                    }

                    if WishKit.config.emailField != .none {
                        VStack(spacing: 0) {
                            HStack {
                                if WishKit.config.emailField == .optional {
                                    Text(WishKit.config.localization.emailOptional)
                                        .font(.caption2)
                                        .padding([.leading, .trailing, .bottom], 5)
                                }

                                if WishKit.config.emailField == .required {
                                    Text(WishKit.config.localization.emailRequired)
                                        .font(.caption2)
                                        .padding([.leading, .trailing, .bottom], 5)
                                }

                                Spacer()
                            }

                            TextField("", text: $emailText)
                                .padding(10)
                                .textFieldStyle(.plain)
                                .foregroundColor(textColor)
                                .background(fieldBackgroundColor)
                                .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
                        }
                    }

                    #if os(macOS) || os(visionOS)
                    Spacer()
                    #endif

                    WKButton(
                        text: WishKit.config.localization.save,
                        action: submitAction,
                        style: .primary,
                        isLoading: $isButtonLoading,
                        size: saveButtonSize
                    )
                    .disabled(isButtonDisabled)
                    .alert(isPresented: $alertModel.showAlert) {

                        switch alertModel.alertReason {
                        case .successfullyCreated:
                            let button = Alert.Button.default(
                                Text(WishKit.config.localization.ok),
                                action: {
                                    createActionCompletion()
                                    dismissAction()
                                }
                            )

                            return Alert(
                                title: Text(WishKit.config.localization.info),
                                message: Text(WishKit.config.localization.successfullyCreated),
                                dismissButton: button
                            )
                        case .createReturnedError(let errorText):
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                            return Alert(
                                title: Text(WishKit.config.localization.info),
                                message: Text(errorText),
                                dismissButton: button
                            )
                        case .emailRequired:
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                            return Alert(
                                title: Text(WishKit.config.localization.info),
                                message: Text(WishKit.config.localization.emailRequiredText),
                                dismissButton: button
                            )
                        case .emailFormatWrong:
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok))

                            return Alert(
                                title: Text(WishKit.config.localization.info),
                                message: Text(WishKit.config.localization.emailFormatWrongText),
                                dismissButton: button
                            )
                        case .none:
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok))
                            return Alert(title: Text(""), dismissButton: button)
                        default:
                            let button = Alert.Button.default(Text(WishKit.config.localization.ok))
                            return Alert(title: Text(""), dismissButton: button)
                        }

                    }
                }
                .frame(maxWidth: 700)
                .padding()

                #if os(iOS)
                Spacer()
                #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .ignoresSafeArea(edges: [.leading, .trailing])
        .toolbarKeyboardDoneButton()
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

    private func showCloseButton() -> Bool {
        #if os(macOS) || os(visionOS)
            return true
        #else
            return false
        #endif
    }

    private func handleTitleAndDescriptionChange() {

        // Keep characters within limits
        let titleLimit = 50
        let descriptionLimit = 500

        if titleText.count > titleLimit {
            titleText = String(titleText.prefix(titleLimit))
        }

        if descriptionText.count > descriptionLimit {
            descriptionText = String(descriptionText.prefix(descriptionLimit))
        }

        // Enable/Disable button
        isButtonDisabled = titleText.isEmpty || descriptionText.isEmpty
    }

    private func submitAction() {

        if WishKit.config.emailField == .required && emailText.isEmpty {
            alertModel.alertReason = .emailRequired
            alertModel.showAlert = true
            return
        }

        let isInvalidEmailFormat = (emailText.count < 6 || !emailText.contains("@") || !emailText.contains("."))
        if !emailText.isEmpty && isInvalidEmailFormat {
            alertModel.alertReason = .emailFormatWrong
            alertModel.showAlert = true
            return
        }

        isButtonLoading = true

        let createRequest = CreateWishRequest(title: titleText, description: descriptionText, email: emailText)
        WishApi.createWish(createRequest: createRequest) { result in
            isButtonLoading = false
            DispatchQueue.main.async {
                switch result {
                case .success:
                    alertModel.alertReason = .successfullyCreated
                    alertModel.showAlert = true
                case .failure(let error):
                    alertModel.alertReason = .createReturnedError(error.reason.description)
                    alertModel.showAlert = true
                }
            }
        }
    }

    private func dismissViewAction() {
        if !titleText.isEmpty || !descriptionText.isEmpty || !emailText.isEmpty {
            showConfirmationAlert = true
        } else {
            crossPlatformDismiss()
        }
    }

    private func crossPlatformDismiss() {
        #if os(macOS) || os(visionOS)
        closeAction?()
        #else
        dismissAction()
        #endif
    }

    private func dismissAction() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Color Scheme

extension CreateWishView {

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
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.tertiaryColor {
                return color.dark
            }

            return PrivateTheme.systemBackgroundColor.dark
        @unknown default:
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        }
    }

    var fieldBackgroundColor: Color {
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
            if let color = WishKit.theme.tertiaryColor {
                return color.light
            }

            return PrivateTheme.systemBackgroundColor.light
        }
    }
}
