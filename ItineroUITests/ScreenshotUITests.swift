//
//  ScreenshotUITests.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

/// UI tests focused on capturing high-quality screenshots
/// for App Store and regression documentation.
final class ScreenshotUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        // Wait for the main UI to be ready
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist for screenshots")
        
        // Print screenshot locations for reference
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let screenshotsDir = desktopURL.appendingPathComponent("ItineroScreenshots")
            print("📸 Screenshots will be saved to: \(screenshotsDir.path)")
        }
        print("📸 Screenshots are also attached to test results - view them in Xcode's Test Navigator")
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Helpers
    
    private func attachScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        
        // Create attachment for test results viewer (visible in Xcode's test navigator)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save to Desktop for easy manual access
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let screenshotsDir = desktopURL.appendingPathComponent("ItineroScreenshots")
            
            // Create directory if it doesn't exist
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: screenshotsDir.path) {
                try? fileManager.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
            }
            
            let fileName = "\(name).png"
            let fileURL = screenshotsDir.appendingPathComponent(fileName)
            
            do {
                try screenshot.pngRepresentation.write(to: fileURL)
                print("📸 Screenshot saved to Desktop: \(fileURL.path)")
            } catch {
                print("⚠️ Failed to save screenshot to Desktop: \(error)")
            }
        }
        
        // Also save to test results directory (accessible via xcresult)
        let testBundleURL = Bundle(for: type(of: self)).bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let screenshotsDir = testBundleURL.appendingPathComponent("Screenshots")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: screenshotsDir.path) {
            try? fileManager.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)
        }
        
        let fileName = "\(name).png"
        let fileURL = screenshotsDir.appendingPathComponent(fileName)
        
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
            print("📸 Screenshot saved to test bundle: \(fileURL.path)")
        } catch {
            print("⚠️ Failed to save screenshot to test bundle: \(error)")
        }
    }
    
    private func navigateToTrips() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
        }
    }
    
    private func navigateToSettings() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
    }
    
    // MARK: - Screenshot Scenarios
    
    /// Capture the main Trips list screen.
    func testCaptureTripsListScreenshot() throws {
        navigateToTrips()
        
        // Give UI a moment to stabilize (e.g. SwiftData loading)
        _ = app.scrollViews.firstMatch.waitForExistence(timeout: 5)
        
        attachScreenshot(named: "01-Trips-List")
    }
    
    /// Capture the Add Trip form screen.
    func testCaptureAddTripFormScreenshot() throws {
        navigateToTrips()
        
        let addButton = app.buttons["Add Trip"].firstMatch
        if !addButton.exists {
            let plusButton = app.buttons.matching(identifier: "add").firstMatch
            if plusButton.exists {
                plusButton.tap()
            } else {
                throw XCTSkip("Add Trip button not available for screenshot scenario")
            }
        } else {
            addButton.tap()
        }
        
        // Wait for Add Trip view
        let addTripNavBar = app.navigationBars["Add Trip"].firstMatch
        guard addTripNavBar.waitForExistence(timeout: 10) else {
            throw XCTSkip("Add Trip view did not appear in time for screenshot scenario")
        }
        
        // Optionally pre-fill the trip name so the form looks realistic
        let nameField = app.textFields["Trip Name"].firstMatch
        if nameField.waitForExistence(timeout: 3) {
            if let currentValue = nameField.value as? String, currentValue.isEmpty {
                nameField.tap()
                nameField.typeText("Summer in Paris")
            }
        }
        
        attachScreenshot(named: "02-Add-Trip-Form")
    }
    
    /// Capture a Settings screen screenshot.
    func testCaptureSettingsScreenshot() throws {
        navigateToSettings()
        
        // Wait briefly for content to load
        _ = app.navigationBars["Settings"].firstMatch.waitForExistence(timeout: 5)
        
        attachScreenshot(named: "03-Settings")
    }
    
    /// Capture a sample trip detail screen if a trip exists.
    func testCaptureTripDetailScreenshot() throws {
        navigateToTrips()
        
        // Try to tap the first visible trip card
        let tripNameElement = app.staticTexts["trip_name"].firstMatch
        if tripNameElement.exists && tripNameElement.isHittable {
            tripNameElement.tap()
        } else if let firstTrip = app.scrollViews.firstMatch.staticTexts.allElementsBoundByIndex.first {
            if firstTrip.isHittable {
                firstTrip.tap()
            }
        }
        
        // Wait for a detail navigation bar (fallback to any nav bar)
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Trip detail view should appear for screenshot")
        
        attachScreenshot(named: "04-Trip-Detail")
    }
}

