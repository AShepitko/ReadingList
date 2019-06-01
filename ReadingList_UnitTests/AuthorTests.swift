//
//  AuthorTests.swift
//  ReadingList_UnitTests
//
//  Created by Alexei Shepitko on 06/02/2019.
//

import XCTest
@testable import ReadingList

class AuthorTests: XCTestCase {

    func testAuthorHasFirstAndLastName() {
        // given
        let firstName = "Alexander"
        let lastName = "Pushkin"

        // when
        let author = Author(lastName: lastName, firstNames: firstName)

        // then
        XCTAssertEqual(author.firstNames, firstName)
        XCTAssertEqual(author.lastName, lastName)
    }

    func testAuthorHasOnlyFirstName() {
        // given
        let lastName = "Gomer"

        // when
        let author = Author(lastName: lastName, firstNames: nil)

        // then
        XCTAssertEqual(author.lastName, lastName)
        XCTAssertNil(author.firstNames)
    }

    func testAuthorDisplayFirstLastName() {
        // given
        let firstName = "Ivan"
        let lastName = "Bunin"
        let sut = Author(lastName: lastName, firstNames: firstName)

        // when
        let display = sut.displayFirstLast

        // then
        XCTAssertEqual(display, "\(firstName) \(lastName)")
    }

    func testAuthorDisplayOnlyLastName() {
        // given
        let lastName = "Gomer"
        let sut = Author(lastName: lastName, firstNames: nil)

        // when
        let display = sut.displayFirstLast

        // then
        XCTAssertEqual(display, "\(lastName)")
    }

    func testAuthorDisplayLastCommaFirstName() {
        // given
        let firstName = "Michael"
        let lastName = "Lermontov"
        let sut = Author(lastName: lastName, firstNames: firstName)

        // when
        let display = sut.displayLastCommaFirst

        // then
        XCTAssertEqual(display, "\(lastName), \(firstName)")
    }

    func testAuthorDisplayOnlyLastCommaFirstName() {
        // given
        let lastName = "Gomer"
        let sut = Author(lastName: lastName, firstNames: nil)

        // when
        let display = sut.displayLastCommaFirst

        // then
        XCTAssertEqual(display, "\(lastName)")
    }

    func testFewAuthorsSort() {
        // given
        let sut = [ Author(lastName: "Pushkin", firstNames: "Alexander"), Author(lastName: "Bunin", firstNames: "Ivan") ]

        // when
        let sort = Author.authorSort(sut)

        // then
        XCTAssertEqual(sort, "pushkin.alexander..bunin.ivan")
    }

    func testOneAuthorSort() {
        // given
        let sut = [ Author(lastName: "Pushkin", firstNames: "Alexander") ]

        // when
        let sort = Author.authorSort(sut)

        // then
        XCTAssertEqual(sort, "pushkin.alexander")
    }

    func testNoAuthorsSort() {
        // given
        let sut: [Author] = []

        // when
        let sort = Author.authorSort(sut)

        // then
        XCTAssertEqual(sort, "")
    }

    func testFewAuthorsDisplay() {
        // given
        let sut = [ Author(lastName: "Pushkin", firstNames: "Alexander"), Author(lastName: "Bunin", firstNames: "Ivan") ]

        // when
        let display = Author.authorDisplay(sut)

        // then
        XCTAssertEqual(display, "Alexander Pushkin, Ivan Bunin")
    }

    func testOneAuthorsDisplay() {
        // given
        let sut = [ Author(lastName: "Pushkin", firstNames: "Alexander") ]

        // when
        let display = Author.authorDisplay(sut)

        // then
        XCTAssertEqual(display, "Alexander Pushkin")
    }

    func testNoAuthorsDisplay() {
        // given
        let sut: [Author] = []

        // when
        let display = Author.authorDisplay(sut)

        // then
        XCTAssertEqual(display, "")
    }

}
