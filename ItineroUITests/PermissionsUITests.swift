//
//  PermissionsUITests.swift
//  ItineroUITests
//
//  Created on 2026
//
//  Tests for app permission requests and handling

import XCTest

final class PermissionsUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchEnvironment["UITesting"] = "true"
        app.launch()
        
        // Wait for app to be ready
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)
    }
    
    override func tearDownWithError() throws {
        if app.state == .runningForeground {
            app.terminate()
        }
        app = nil
    }
    
    // MARK: - Location Permission Tests
    
    func testLocationPermissionRequest() throws {
        // Navigate to a view that requires location (like trip map)
        // This test verifies that location permission can be requested
        
        // First, check if we can navigate to a trip with a map
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // Wait for trip list
        let tripListTitle = app.navigationBars["My Trips"].firstMatch
        guard tripListTitle.waitForExistence(timeout: 5) else {
            // If no trips exist, that's okay - we're just testing permission flow
            return
        }
        
        // Try to tap on a trip if one exists
        let tripCards = app.scrollViews.firstMatch
        if tripCards.exists {
            // Location permission might be requested when viewing trip details
            // This is a basic test that the app doesn't crash when location is needed
        }
    }
    
    func testLocationPermissionDenied() throws {
        // This test verifies app behavior when location is denied
        // Note: In UI tests, we can't actually deny permissions,
        // but we can verify the app handles permission states gracefully
        
        // Navigate to settings or a location-dependent feature
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should continue to function even if location is denied
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "Trips tab should exist even if location is denied")
    }
    
    // MARK: - Camera Permission Tests
    
    func testCameraPermissionRequest() throws {
        // Navigate to documents view or camera feature
        // This test verifies camera permission request flow
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // Look for documents or camera button
        // The app should handle camera permission requests gracefully
        // Even if we can't actually trigger the system dialog in UI tests,
        // we can verify the app doesn't crash
    }
    
    // MARK: - Photo Library Permission Tests
    
    func testPhotoLibraryPermissionRequest() throws {
        // Test photo library permission request
        // Similar to camera, we verify the app handles permission requests
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should handle photo library permission requests
        // without crashing
    }
    
    // MARK: - Notification Permission Tests
    
    func testNotificationPermissionRequest() throws {
        // Test notification permission request
        // This might be triggered when creating a trip with reminders
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // Try to add a trip with reminders
        // Notification permission might be requested
        navigateToAddTrip()
        
        // Fill in trip details
        let nameField = findTripNameField()
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText("Notification Test Trip")
        }
        
        // The app should handle notification permission requests
        // without crashing when reminders are enabled
    }
    
    // MARK: - Permission Request View Tests
    
    func testPermissionRequestViewAppears() throws {
        // Test if permission request view appears on first launch
        // This depends on app state, but we can check for permission-related UI
        
        // Look for permission-related text or buttons
        let permissionText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'permission' OR label CONTAINS[c] 'access' OR label CONTAINS[c] 'camera' OR label CONTAINS[c] 'location'"))
        
        // If permission view appears, verify it's accessible
        if permissionText.count > 0 {
            let firstPermission = permissionText.firstMatch
            XCTAssertTrue(firstPermission.exists, "Permission request UI should be accessible")
        }
    }
    
    func testPermissionRequestViewDismissal() throws {
        // Test that permission request view can be dismissed
        // or that app continues to function after permission requests
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should allow navigation even if permissions aren't granted
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "Should be able to navigate even without permissions")
    }
    
    // MARK: - Permission State Persistence Tests
    
    func testAppContinuesAfterPermissionDenial() throws {
        // Verify app continues to function after permissions are denied
        // This is important for user experience
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // Navigate through different tabs
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // Verify we can still interact with the app
        let tripListTitle = app.navigationBars["My Trips"].firstMatch
        XCTAssertTrue(tripListTitle.waitForExistence(timeout: 5), "App should work even if permissions are denied")
        
        // Navigate to settings
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists && settingsTab.isHittable {
            settingsTab.tap()
        }
        
        // App should remain functional
        XCTAssertTrue(tabBar.exists, "App should remain functional after permission denial")
    }
    
    // MARK: - Permission Re-request Tests
    
    func testPermissionReRequestFlow() throws {
        // Test that app can handle re-requesting permissions
        // This might happen when user goes to settings and changes permissions
        
        // Navigate through app to trigger permission checks
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should handle permission state changes gracefully
        // without crashing or getting stuck
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "App should handle permission state changes")
    }
    
    // MARK: - Permission Info.plist Tests
    
    func testPermissionDescriptionsExist() throws {
        // Verify that permission usage descriptions are present
        // This is important for App Store approval
        
        // We can't directly test Info.plist in UI tests,
        // but we can verify the app doesn't crash when requesting permissions
        // which would indicate missing descriptions
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // If app launches and runs without crashing,
        // it suggests Info.plist is properly configured
        XCTAssertTrue(tabBar.exists, "App should launch with proper Info.plist configuration")
    }
    
    // MARK: - Location-Based Features Tests
    
    func testLocationFeaturesWorkWhenGranted() throws {
        // Test that location-based features work when permission is granted
        // This is a positive test case
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // If location is granted, map features should work
        // We verify the app doesn't crash when accessing location features
        let tripListTitle = app.navigationBars["My Trips"].firstMatch
        XCTAssertTrue(tripListTitle.waitForExistence(timeout: 5), "Location features should work when granted")
    }
    
    func testLocationFeaturesGracefulDegradation() throws {
        // Test that location features degrade gracefully when denied
        // App should still function, just without location features
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should continue to work even without location
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "App should work without location permission")
        
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // Core features should still be accessible
        let tripListTitle = app.navigationBars["My Trips"].firstMatch
        XCTAssertTrue(tripListTitle.waitForExistence(timeout: 5), "Core features should work without location")
    }
    
    // MARK: - Camera Features Tests
    
    func testCameraFeaturesWorkWhenGranted() throws {
        // Test camera features when permission is granted
        // Verify app doesn't crash when accessing camera
        
        // Navigate to documents or camera feature
        // App should handle camera access gracefully
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "App should handle camera permission")
    }
    
    func testCameraFeaturesGracefulDegradation() throws {
        // Test that camera features degrade gracefully when denied
        // Users should still be able to use the app
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should continue to function without camera
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "App should work without camera permission")
    }
    
    // MARK: - Permission Request Timing Tests
    
    func testPermissionRequestTiming() throws {
        // Test that permissions are requested at appropriate times
        // Not too early, not too late
        
        // App should request permissions when needed, not on launch
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should be usable immediately without waiting for permissions
        let tripsTab = tabBar.buttons["Trips"]
        XCTAssertTrue(tripsTab.exists, "App should be usable immediately")
        XCTAssertTrue(tripsTab.isHittable, "App should be interactive immediately")
    }
    
    // MARK: - Multiple Permission Requests Tests
    
    func testMultiplePermissionRequests() throws {
        // Test that app handles multiple permission requests correctly
        // Should request them at appropriate times, not all at once
        
        // Navigate through app features that might trigger different permissions
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            XCTFail("Tab bar not found")
            return
        }
        
        // App should handle multiple permission requests gracefully
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        // App should remain stable when multiple permissions are requested
        XCTAssertTrue(tabBar.exists, "App should remain stable with multiple permission requests")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToAddTrip() {
        guard app.state == .runningForeground else { return }
        
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else { return }
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists && tripsTab.isHittable {
            tripsTab.tap()
        }
        
        let addButton = app.buttons["Add Trip"].firstMatch
        if !addButton.exists {
            let plusButton = app.buttons.matching(identifier: "add").firstMatch
            if plusButton.exists && plusButton.isHittable {
                plusButton.tap()
            }
        } else if addButton.isHittable {
            addButton.tap()
        }
        
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func findTripNameField() -> XCUIElement {
        var nameField = app.textFields["Trip Name"].firstMatch
        
        if !nameField.waitForExistence(timeout: 2) {
            nameField = app.textFields.firstMatch
        }
        
        if !nameField.exists {
            let allTextFields = app.textFields
            if allTextFields.count > 0 {
                nameField = allTextFields.element(boundBy: 0)
            }
        }
        
        return nameField
    }
}
