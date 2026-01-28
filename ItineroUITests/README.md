# UI Automation Tests

This directory contains UI automation tests using XCUITest framework for the Itinero app.

## Test Files

- **ItineroUITests.swift** - Main UI tests including navigation, accessibility, and performance tests
- **TripManagementUITests.swift** - Tests for trip creation, editing, and deletion flows
- **ExpenseTrackingUITests.swift** - Tests for expense tracking functionality
- **ItineraryUITests.swift** - Tests for itinerary and activity management
- **UITestHelpers.swift** - Helper extensions and utilities for UI testing

## Setup Instructions

### 1. Add UI Test Target in Xcode

1. Open `Itinero.xcworkspace` in Xcode
2. Go to **File** → **New** → **Target**
3. Select **iOS** → **UI Testing Bundle**
4. Name it `ItineroUITests`
5. Ensure the target to test is set to `Itinero`
6. Click **Finish**

### 2. Add Test Files to Target

1. Select all files in the `UITests` directory
2. In the File Inspector (right panel), check **ItineroUITests** under **Target Membership**
3. Ensure all test files are included

### 3. Configure Test Target

1. Select the **ItineroUITests** target in the project navigator
2. Go to **Build Settings**
3. Set **Product Bundle Identifier** to `com.ntriply.app.UITests`
4. Set **Test Host** to `$(BUILT_PRODUCTS_DIR)/Itinero.app`
5. Set **Bundle Loader** to `$(TEST_HOST)`

### 4. Update Test Scheme

1. Go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Test** in the left sidebar
3. Click **+** to add test targets
4. Select **ItineroUITests**
5. Click **Close**

## Running Tests

### In Xcode
1. Select the **ItineroUITests** scheme
2. Press **⌘U** to run all tests
3. Or click the diamond icon next to individual test methods

### Command Line
```bash
xcodebuild test \
  -workspace Itinero.xcworkspace \
  -scheme Itinero \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## Test Coverage

### Navigation Tests
- Main tab navigation
- View transitions
- Back button functionality

### Trip Management
- Create new trip
- Edit trip details
- Delete trip
- View trip list

### Expense Tracking
- Add expense
- Edit expense
- View expense list
- Expense calculations

### Itinerary Management
- Add activity
- Edit activity
- Reorder activities
- Mark activities complete

### Accessibility
- VoiceOver labels
- Accessibility identifiers
- Dynamic Type support

### Performance
- App launch time
- UI responsiveness
- Memory usage

## Writing New Tests

### Basic Test Structure
```swift
func testFeatureName() throws {
    // Arrange
    let app = XCUIApplication()
    app.launch()
    
    // Act
    app.buttons["Button"].tap()
    
    // Assert
    XCTAssertTrue(app.staticTexts["Expected Text"].exists)
}
```

### Best Practices

1. **Use accessibility identifiers** - Add `.accessibilityIdentifier()` to SwiftUI views
2. **Wait for elements** - Use `waitForExistence(timeout:)` before interacting
3. **Clean up** - Reset app state in `tearDown()`
4. **Use helper methods** - Reuse navigation and interaction code
5. **Test user flows** - Focus on complete user journeys, not just individual components

## Debugging Tests

### View Hierarchy
Add this to pause execution and inspect UI:
```swift
XCUIDevice.shared.press(.home)
```

### Screenshots
```swift
let screenshot = XCUIScreen.main.screenshot()
let attachment = XCTAttachment(screenshot: screenshot)
attachment.lifetime = .keepAlways
add(attachment)
```

### Logging
```swift
print(app.debugDescription) // Print entire UI hierarchy
```

## Continuous Integration

Add to your CI/CD pipeline:
```yaml
- name: Run UI Tests
  run: |
    xcodebuild test \
      -workspace Itinero.xcworkspace \
      -scheme Itinero \
      -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Troubleshooting

### Tests fail to find elements
- Add accessibility identifiers to SwiftUI views
- Increase timeout values
- Check if element is visible before interacting

### Tests are flaky
- Add explicit waits
- Use `waitForExistence` instead of `sleep`
- Ensure app state is reset between tests

### Performance issues
- Run tests on physical devices for more accurate results
- Use `measure` blocks for performance tests
- Profile with Instruments if needed
