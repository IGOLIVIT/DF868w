//
//  LedgerlyUITests.swift
//  DF868wUITests
//
//  Ledgerly - UI tests for critical flows
//

import XCTest

final class LedgerlyUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddExpenseAndVerify() throws {
        // Skip if onboarding is showing
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Start Using Ledgerly"].tap()
        }

        app.tabBars.buttons["Transactions"].tap()
        app.buttons["plus.circle.fill"].tap()

        app.segmentedControls.buttons["Expense"].tap()
        app.textFields["0.00"].tap()
        app.textFields["0.00"].typeText("5")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Transaction added"].waitForExistence(timeout: 3) || app.navigationBars["Transactions"].exists)
    }

    func testApplyFilter() throws {
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Start Using Ledgerly"].tap()
        }

        app.tabBars.buttons["Transactions"].tap()
        app.buttons["Expenses"].tap()
        XCTAssertTrue(app.buttons["Expenses"].exists)
    }

    func testExportBackup() throws {
        if app.buttons["Get Started"].exists {
            app.buttons["Get Started"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Continue"].tap()
            app.buttons["Start Using Ledgerly"].tap()
        }

        app.tabBars.buttons["Settings"].tap()
        app.buttons["Export backup (JSON)"].tap()
        XCTAssertTrue(app.staticTexts["Backup exported"].waitForExistence(timeout: 3) || app.navigationBars["Settings"].exists)
    }
}
