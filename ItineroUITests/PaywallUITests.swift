//
//  PaywallUITests.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

/// Verifies the RevenueCat paywall loads real subscription options and the
/// legal/restore controls Apple requires (guideline 3.1.2) are reachable.
final class PaywallUITests: XCTestCase {

    private let pricePredicate = NSPredicate(
        format: "label CONTAINS '£' OR label CONTAINS '$' OR label CONTAINS '€'"
    )

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func paywallOnScreen(_ app: XCUIApplication) -> Bool {
        // Our PaywallView wrapper pins a Terms of Use / Privacy Policy footer.
        app.links["Terms of Use"].exists || app.buttons["Terms of Use"].firstMatch.isHittable
    }

    func testPaywallLoadsAndSettingsIsClean() throws {
        let app = XCUIApplication()
        app.launch()

        // Skip onboarding if shown (first launch)
        app.tapIfExists(app.buttons["Skip"])

        // A one-time post-onboarding paywall may present ~0.5s after dismissal.
        sleep(3)
        var priceVerified = false
        if paywallOnScreen(app), !app.tabBars.buttons["Settings"].isHittable {
            let price = app.staticTexts.matching(pricePredicate).firstMatch
            priceVerified = price.waitForExistence(timeout: 30)
            XCTAssertTrue(priceVerified, "Post-onboarding paywall should show package prices")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Post-onboarding paywall"
            shot.lifetime = .keepAlways
            add(shot)
            app.swipeDown(velocity: .fast)
            sleep(1)
        }

        // The exact App Review rejection repro: opening Settings must not
        // produce an error alert.
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3),
                       "No alert should appear when opening Settings")

        // Scroll to the Pro section and verify the 3.1.2 compliance rows.
        let upgrade = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'upgrade_pro' OR label CONTAINS 'Upgrade'")
        ).firstMatch
        var attempts = 0
        while !upgrade.isHittable && attempts < 6 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5), "Upgrade control should exist in Settings")
        XCTAssertTrue(app.buttons["Restore Purchases"].exists, "Restore row should exist")

        if !priceVerified {
            // Open the paywall from Settings and confirm packages load.
            upgrade.tap()
            let price = app.staticTexts.matching(pricePredicate).firstMatch
            XCTAssertTrue(price.waitForExistence(timeout: 30),
                          "Paywall should display at least one price, proving offerings loaded")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "RevenueCat Paywall (Settings)"
            shot.lifetime = .keepAlways
            add(shot)
        }
    }
}
