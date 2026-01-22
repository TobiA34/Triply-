//
//  HapticManager.swift
//  Itinero
//
//  Created on 2024
//

import Foundation
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    // Keep generators as instance variables for better performance
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    private var notificationGenerator: UINotificationFeedbackGenerator?
    
    private init() {}
    
    // Impact feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        // Use main thread for haptic feedback
        DispatchQueue.main.async {
            // Always create a new generator for impact to ensure correct style
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    // Notification feedback
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        DispatchQueue.main.async { [weak self] in
            if self?.notificationGenerator == nil {
                self?.notificationGenerator = UINotificationFeedbackGenerator()
            }
            
            self?.notificationGenerator?.prepare()
            self?.notificationGenerator?.notificationOccurred(type)
        }
    }
    
    // Selection feedback
    func selection() {
        DispatchQueue.main.async { [weak self] in
            if self?.selectionGenerator == nil {
                self?.selectionGenerator = UISelectionFeedbackGenerator()
            }
            
            self?.selectionGenerator?.prepare()
            self?.selectionGenerator?.selectionChanged()
        }
    }
    
    // Success feedback
    func success() {
        notification(.success)
    }
    
    // Error feedback
    func error() {
        notification(.error)
    }
    
    // Warning feedback
    func warning() {
        notification(.warning)
    }
}


