//
//  UITestHelpers.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

extension XCUIApplication {
    /// Wait for an element to appear with a timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// Tap on element if it exists
    func tapIfExists(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 2) {
            element.tap()
        }
    }
    
    /// Scroll to element if needed
    func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement) {
        while !element.isVisible && scrollView.exists {
            scrollView.swipeUp()
        }
    }
}

extension XCUIElement {
    /// Check if element is visible on screen
    var isVisible: Bool {
        guard exists && !frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(frame)
    }
    
    /// Clear text field
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
    
    /// Type text safely
    func safeTypeText(_ text: String) {
        if waitForExistence(timeout: 2) {
            tap()
            typeText(text)
        }
    }
}

/// Test data factory for UI tests
struct UITestDataFactory {
    static func createTestTripName() -> String {
        return "Test Trip \(Int.random(in: 1000...9999))"
    }
    
    static func createTestDestination() -> String {
        let destinations = ["Paris, France", "Tokyo, Japan", "New York, USA", "London, UK"]
        return destinations.randomElement() ?? "Paris, France"
    }
    
    static func createTestExpenseAmount() -> String {
        return String(format: "%.2f", Double.random(in: 10...500))
    }
}
