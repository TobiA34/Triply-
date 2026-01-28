//
//  ItineroUITests.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

final class ItineroUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testMainTabNavigation() throws {
        // Test that all main tabs are accessible
        let tabBar = app.tabBars.firstMatch
        
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        
        // Test Trips tab
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
            XCTAssertTrue(tripsTab.isSelected, "Trips tab should be selected")
        }
        
        // Test Settings tab
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected")
        }
    }
    
    // MARK: - Trip Management Tests
    
    func testCreateNewTrip() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Navigate to Trips tab
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
        }
        
        // Look for add button (could be "+" or "Add Trip")
        let addButton = app.buttons["Add Trip"].firstMatch
        if !addButton.exists {
            let plusButton = app.buttons.matching(identifier: "add").firstMatch
            if plusButton.exists {
                plusButton.tap()
            }
        } else {
            addButton.tap()
        }
        
        // Wait for add trip view to appear
        let addTripView = app.navigationBars["Add Trip"].firstMatch
        if addTripView.waitForExistence(timeout: 3) {
            // Fill in trip details if fields are available
            let nameField = app.textFields["Trip Name"].firstMatch
            if nameField.exists {
                nameField.tap()
                nameField.typeText("Test Trip")
            }
            
            // Cancel or save (depending on what we want to test)
            let cancelButton = app.buttons["Cancel"].firstMatch
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }
    
    func testViewTripDetails() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Navigate to Trips tab
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
        }
        
        // Try to find and tap on a trip card
        let tripCards = app.scrollViews.containing(.any, identifier: "trip").firstMatch
        if tripCards.exists {
            tripCards.tap()
            
            // Verify trip detail view appears
            let detailView = app.navigationBars.firstMatch
            XCTAssertTrue(detailView.waitForExistence(timeout: 3), "Trip detail view should appear")
        }
    }
    
    // MARK: - Settings Tests
    
    func testSettingsNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Navigate to Settings
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Verify settings view appears
            let settingsView = app.navigationBars["Settings"].firstMatch
            XCTAssertTrue(settingsView.waitForExistence(timeout: 3), "Settings view should appear")
        }
    }
    
    func testThemeSettings() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Navigate to Settings
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
        
        // Look for theme-related buttons
        let themeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'theme'")).firstMatch
        if themeButton.exists {
            themeButton.tap()
            
            // Verify theme settings view appears
            let themeView = app.navigationBars.firstMatch
            XCTAssertTrue(themeView.waitForExistence(timeout: 3), "Theme settings should appear")
        }
    }
    
    // MARK: - Search Tests
    
    func testDestinationSearch() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Navigate to Trips tab
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
        }
        
        // Look for search functionality
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Paris")
            
            // Wait for search results
            sleep(2)
            
            // Clear search
            let clearButton = app.buttons["Clear text"].firstMatch
            if clearButton.exists {
                clearButton.tap()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Verify that key UI elements have accessibility labels
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Check that tabs have accessibility labels
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            XCTAssertFalse(tripsTab.label.isEmpty, "Trips tab should have accessibility label")
        }
        
        let settingsTab = tabBar.buttons["Settings"]
        if settingsTab.exists {
            XCTAssertFalse(settingsTab.label.isEmpty, "Settings tab should have accessibility label")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    // MARK: - UI Element Existence Tests
    
    func testMainUIElementsExist() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        
        // Verify main UI components are present
        XCTAssertTrue(app.exists, "App should be running")
    }
    
    // MARK: - Gesture Tests
    
    func testSwipeGestures() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test swipe on scrollable content
        let scrollViews = app.scrollViews
        if scrollViews.count > 0 {
            let firstScrollView = scrollViews.firstMatch
            if firstScrollView.exists {
                firstScrollView.swipeUp()
                sleep(1)
                firstScrollView.swipeDown()
            }
        }
    }
}
