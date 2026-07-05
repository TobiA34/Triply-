//
//  PaywallUITests.swift
//  ItineroUITests
//
//  Created on 2026
//

import XCTest

/// Verifies the App Review rejection repro is fixed: Settings never shows an
/// error alert, subscription legal/restore controls exist (guideline 3.1.2),
/// and tapping Upgrade either shows a priced paywall or fails silently with
/// an inline message — never an alert.
final class PaywallUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSettingsIsCleanAndUpgradeNeverAlerts() throws {
        let app = XCUIApplication()
        app.launch()

        // Skip onboarding if shown (first launch)
        app.tapIfExists(app.buttons["Skip"])
        sleep(2)

        // A one-time post-onboarding paywall may present; dismiss it.
        if !app.tabBars.buttons["Settings"].isHittable {
            app.swipeDown(velocity: .fast)
            sleep(1)
        }

        // The exact App Review rejection repro: opening Settings must not
        // produce an error alert.
        app.tabBars.buttons["Settings"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3),
                       "No alert should appear when opening Settings")

        // Pro section is the FIRST section — its rows must be present.
        let upgrade = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == 'upgrade_pro' OR label CONTAINS 'Upgrade'")
        ).firstMatch
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5), "Upgrade control should exist in Settings")
        XCTAssertTrue(app.buttons["Restore Purchases"].exists, "Restore row should exist")

        // Tap Upgrade. Whatever happens (offerings loaded or not), the user
        // must NEVER see an error alert — the class of bug Apple rejected.
        upgrade.tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 10),
                       "Tapping Upgrade must never surface an error alert")

        // If the paywall sheet presented, it must show a real price. Scope the
        // search to elements that appeared with the paywall (Terms of Use
        // footer marks our wrapper), so Settings' own currency rows can't
        // create a false positive.
        let paywallFooter = app.staticTexts["Terms of Use"]
        if paywallFooter.waitForExistence(timeout: 5) && !app.tabBars.buttons["Settings"].isHittable {
            let price = app.staticTexts.matching(
                NSPredicate(format: "(label CONTAINS '£' OR label CONTAINS '$' OR label CONTAINS '€') AND NOT label CONTAINS '1000'")
            ).firstMatch
            XCTAssertTrue(price.waitForExistence(timeout: 30),
                          "Presented paywall should display at least one package price")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "RevenueCat Paywall"
            shot.lifetime = .keepAlways
            add(shot)
        } else {
            // Paywall was correctly suppressed; the inline message explains why.
            let inlineMessage = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'available right now'")
            ).firstMatch
            XCTAssertTrue(inlineMessage.waitForExistence(timeout: 10),
                          "Suppressed paywall should surface an inline explanation, not an alert")
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Settings with inline unavailable message"
            shot.lifetime = .keepAlways
            add(shot)
        }

        XCTAssertFalse(app.alerts.firstMatch.exists, "Still no alerts at the end of the flow")
    }
}
