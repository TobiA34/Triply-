//
//  View+Keyboard.swift
//  Itinero
//
//  Keyboard dismissal utilities for SwiftUI views
//

import SwiftUI
import UIKit

extension View {
    /// Dismisses the keyboard when tapping outside text fields
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
    
    /// Dismisses keyboard when dragging down
    func dismissKeyboardOnDrag() -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onEnded { _ in
                    hideKeyboard()
                }
        )
    }
    
    /// Adds both tap and drag to dismiss keyboard
    func dismissKeyboard() -> some View {
        self
            .dismissKeyboardOnTap()
            .dismissKeyboardOnDrag()
    }
    
    /// Adds a "Done" button to the keyboard toolbar
    @ViewBuilder
    func keyboardDoneButton() -> some View {
        #if canImport(UIKit) && !os(visionOS)
        if #available(iOS 15.0, *) {
            self.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        } else {
            self
        }
        #else
        self
        #endif
    }
    
    /// Hides keyboard when view appears (useful for forms)
    func hideKeyboardOnAppear() -> some View {
        self.onAppear {
            hideKeyboard()
        }
    }
}

// MARK: - Keyboard Helper Functions

/// Hides the keyboard programmatically
func hideKeyboard() {
    #if canImport(UIKit)
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
    #endif
}

// MARK: - Keyboard Dismiss Modifier

struct KeyboardDismissModifier: ViewModifier {
    let onTap: Bool
    let onDrag: Bool
    let showDoneButton: Bool
    
    init(onTap: Bool = true, onDrag: Bool = true, showDoneButton: Bool = false) {
        self.onTap = onTap
        self.onDrag = onDrag
        self.showDoneButton = showDoneButton
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        base(content: content)
            .modifier(KeyboardDoneToolbarModifier(enabled: showDoneButton))
    }
    
    @ViewBuilder
    private func base(content: Content) -> some View {
        if onTap && onDrag {
            content
                .simultaneousGesture(
                    TapGesture().onEnded { hideKeyboard() }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { _ in hideKeyboard() }
                )
        } else if onTap {
            content
                .simultaneousGesture(
                    TapGesture().onEnded { hideKeyboard() }
                )
        } else if onDrag {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { _ in hideKeyboard() }
                )
        } else {
            content
        }
    }
}

private struct KeyboardDoneToolbarModifier: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if canImport(UIKit) && !os(visionOS)
        if #available(iOS 15.0, *) {
            if enabled {
                content.toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { hideKeyboard() }
                    }
                }
            } else {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    /// Comprehensive keyboard dismiss with customizable options
    func keyboardDismissable(
        onTap: Bool = true,
        onDrag: Bool = true,
        showDoneButton: Bool = false
    ) -> some View {
        self.modifier(KeyboardDismissModifier(
            onTap: onTap,
            onDrag: onDrag,
            showDoneButton: showDoneButton
        ))
    }
}

