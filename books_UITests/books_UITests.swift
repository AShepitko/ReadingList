//
//  books_UITests.swift
//  books_UITests
//
//  Created by Andrew Bennet on 25/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import XCTest

class books_UITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let app = ReadingListApplication()
        app.launch()

        // Add some test data
        app.addTestData()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddManualBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        
        let initialNumberOfCells = Int(app.tables.cells.count)
        app.clickAddButton(addMethod: .enterManually)
        
        // Add some book metadata
        app.textFields.element(boundBy: 0).tap()
        app.typeText("The Catcher in the Rye")
        app.textFields.element(boundBy: 1).tap()
        app.typeText("J. D. Salinger")
        
        app.topNavBar.buttons["Next"].tap()
        app.topNavBar.buttons["Done"].tap()
        
        sleep(1)
        XCTAssertEqual(app.tables.cells.count, UInt(initialNumberOfCells + 1))
    }
    
    func testEditBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        app.tables.cells.element(boundBy: 0).tap()
        app.topNavBar.buttons["Edit"].tap()
        app.sheets.buttons.element(boundBy: 1).tap()
        
        app.tables.staticTexts["Title"].tap()
        app.typeText("changed!")
        app.topNavBar.buttons["Done"].tap()
    }
    
    func testDeleteBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.toRead)
        let bookCount = Int(app.tables.element(boundBy: 0).cells.count)
        
        app.tables.cells.element(boundBy: 0).tap()
        app.topNavBar.buttons["Edit"].tap()
        app.sheets.buttons.element(boundBy: 1).tap()
        
        app.tables.staticTexts["Delete"].tap()
        app.sheets.buttons["Delete"].tap()
        
        sleep(1)
        XCTAssertEqual(app.tables.cells.count, UInt(bookCount - 1))
    }
    
    func testExportBook() {
        let app = ReadingListApplication()
        
        app.clickTab(.settings)
        app.tables.staticTexts["Export Data"].tap()
        
        sleep(2)
        app.collectionViews.collectionViews.buttons["Add To iCloud Drive"].tap()
        app.navigationBars["iCloud Drive"].buttons["Cancel"].tap()
    }
    
    private func scanBarcode(app: ReadingListApplication, mode: BarcodeScanSimulation) {
        app.setBarcodeSimulation(mode)
        app.clickTab(.toRead)
        
        app.navigationBars["To Read"].buttons["Add"].tap()
        app.sheets.buttons["Scan Barcode"].tap()
    }
    
    func testBarcodeScannerNormal() {
        let app = ReadingListApplication()
        
        // Normal mode
        scanBarcode(app: app, mode: .normal)
        sleep(1)
        app.topNavBar.buttons["Cancel"].tap()
    }
    
    func testBarcodeScannerNoPermissions() {
        let app = ReadingListApplication()
        
        // No permissions
        scanBarcode(app: app, mode: .noCameraPermissions)
        sleep(1)
        XCTAssertEqual(app.alerts.count, 1)
        let permissionAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("Permission Required", permissionAlert.label)
        permissionAlert.buttons["Cancel"].tap()
    }
    
    func testBarcodeScannerValidIsbn() {
        let app = ReadingListApplication()
        
        // Valid ISBN
        scanBarcode(app: app, mode: .validIsbn)
        sleep(5)
        app.topNavBar.buttons["Done"].tap()
        
    }
    
    func testBarcodeScannerNotFoundIsbn() {
        let app = ReadingListApplication()
        
        // Not found ISBN
        scanBarcode(app: app, mode: .unfoundIsbn)
        sleep(2)
        XCTAssertEqual(app.alerts.count, 1)
        let noMatchAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("No Exact Match", noMatchAlert.label)
        noMatchAlert.buttons["No"].tap()
        app.topNavBar.buttons["Cancel"].tap()
        
    }
    
    func testBarcodeScannerExistingIsbn() {
        let app = ReadingListApplication()
        
        // Existing ISBN
        scanBarcode(app: app, mode: .existingIsbn)
        sleep(1)
        XCTAssertEqual(app.alerts.count, 1)
        let duplicateAlert = app.alerts.element(boundBy: 0)
        XCTAssertEqual("Book Already Added", duplicateAlert.label)
        duplicateAlert.buttons["Cancel"].tap()
        app.topNavBar.buttons["Cancel"].tap()
    }
}
