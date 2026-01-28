//
//  ExpenseTrackingUITests.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

final class ExpenseTrackingUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Add Expense Tests
    
    func testAddExpense() throws {
        navigateToTrip()
        
        // Look for expenses section or button
        let expenseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'expense'")).firstMatch
        if expenseButton.exists {
            expenseButton.tap()
            
            // Look for add expense button
            let addExpenseButton = app.buttons["Add Expense"].firstMatch
            if addExpenseButton.exists {
                addExpenseButton.tap()
                
                // Fill in expense details
                fillExpenseDetails(amount: "50.00", category: "Food", description: "Lunch")
                
                // Save expense
                let saveButton = app.buttons["Save"].firstMatch
                if saveButton.exists {
                    saveButton.tap()
                }
            }
        }
    }
    
    func testExpenseListDisplay() throws {
        navigateToTrip()
        
        // Navigate to expenses
        let expenseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'expense'")).firstMatch
        if expenseButton.exists {
            expenseButton.tap()
            
            // Verify expense list appears
            let expenseList = app.scrollViews.firstMatch
            XCTAssertTrue(expenseList.waitForExistence(timeout: 3), "Expense list should appear")
        }
    }
    
    // MARK: - Expense Editing
    
    func testEditExpense() throws {
        navigateToExpense()
        
        // Look for edit button
        let editButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'edit'")).firstMatch
        if editButton.exists {
            editButton.tap()
            
            // Modify amount
            let amountField = app.textFields.firstMatch
            if amountField.exists {
                amountField.tap()
                amountField.clearText()
                amountField.typeText("75.00")
            }
            
            // Save
            let saveButton = app.buttons["Save"].firstMatch
            if saveButton.exists {
                saveButton.tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToTrip() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let tripsTab = tabBar.buttons["Trips"]
        if tripsTab.exists {
            tripsTab.tap()
        }
        
        // Tap on first trip
        let tripCard = app.scrollViews.firstMatch
        if tripCard.exists {
            tripCard.tap()
        }
    }
    
    private func navigateToExpense() {
        navigateToTrip()
        
        let expenseButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'expense'")).firstMatch
        if expenseButton.exists {
            expenseButton.tap()
        }
        
        // Tap on first expense
        let expenseItem = app.scrollViews.firstMatch
        if expenseItem.exists {
            expenseItem.tap()
        }
    }
    
    private func fillExpenseDetails(amount: String, category: String, description: String) {
        let amountField = app.textFields["Amount"].firstMatch
        if amountField.exists {
            amountField.tap()
            amountField.typeText(amount)
        }
        
        let categoryField = app.textFields["Category"].firstMatch
        if categoryField.exists {
            categoryField.tap()
            categoryField.typeText(category)
        }
        
        let descriptionField = app.textFields["Description"].firstMatch
        if descriptionField.exists {
            descriptionField.tap()
            descriptionField.typeText(description)
        }
    }
}
