//
//  BookModelTests.swift
//  ReadingList_UnitTests
//
//  Created by Maru on 07/02/2019.
//

import XCTest
import CoreData
import ReadingList_Foundation

@testable import ReadingList

class MockCoreDataStack {

    lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))])!
        return managedObjectModel
    }()

    lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(inMemoryStoreWithName: "books")
        container.loadPersistentStores { description, error in
            precondition(description.type == NSInMemoryStoreType)

            if let error = error {
                fatalError("Create an in-mem coordinator failed \(error)")
            }
        }

        return container
    }()

    var mainContext: NSManagedObjectContext {
        return mockPersistentContainer.viewContext
    }

    // MARK: - Actions

    func saveMainContext() {
        do {
            try mainContext.save()
        } catch {
            print("create fakes error \(error)")
        }
    }

    func flushData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        let objs = try! mockPersistentContainer.viewContext.fetch(fetchRequest)
        for case let obj as NSManagedObject in objs {
            mockPersistentContainer.viewContext.delete(obj)
        }

        try! mockPersistentContainer.viewContext.save()
    }
}

class BookModelTests: XCTestCase {

    var mockCoreDataStack = MockCoreDataStack()

    // MARK: - Tests

    func testBookCreationSavesReadState() {
        let readState: BookReadState = .toRead
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)

        XCTAssertEqual(sut.readState, readState)
    }

    func testReadingStateSetsDate() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .reading)

        XCTAssertNotNil(sut.startedReading)
    }

    func testToReadStateNotSetStartingDate() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)

        XCTAssertNil(sut.startedReading)
    }

    func testFinishedStateSetsStartingAndFinishingDates() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .finished)

        XCTAssertNotNil(sut.startedReading, "Starting reading date not set")
        XCTAssertNotNil(sut.finishedReading, "Finishing reading date not set")
    }

    func testSetAuthors() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        let authors = [Author(lastName: "Test", firstNames: "Test")]

        sut.setAuthors(authors)

        XCTAssertEqual(sut.authors, authors)
    }

    func testGetBookByGoogleIdReturnsBook() {
        let bookId = "1"
        _ = insertBookItem(title: "Book 1",
                           googleBooksId: bookId,
                           authors: [Author(lastName: "Smith", firstNames: "Jhon")])

        mockCoreDataStack.saveMainContext()
        let book = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: bookId, isbn: nil)

        XCTAssertEqual(book?.googleBooksId, bookId)
    }

    func testGetBookByIsdnReturnsBook() {
        let bookIsbn: String = "9780451524935"
        _ = insertBookItem(title: "Book 2",
                           manualId: "2",
                           isbn: bookIsbn,
                           authors: [Author(lastName: "Smith", firstNames: "Jhon")])

        mockCoreDataStack.saveMainContext()
        let book = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: nil, isbn: bookIsbn)

        XCTAssertEqual(book?.isbn13, isbnNumber(from: bookIsbn))
    }

    func testEmptyTitleThrowsValidationError() {
        let book = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        book.title = String()
        book.setAuthors([Author(lastName: "Test", firstNames: "Author")])
        book.manualBookId = UUID().uuidString

        XCTAssertThrowsError(try book.validateForUpdate(), "Incorret title doesn't generate validation error")
    }

    func testNotEmptyTitlePassesValidation() {
        let book = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        book.title = "Test"
        book.setAuthors([Author(lastName: "Test", firstNames: "Author")])
        book.manualBookId = UUID().uuidString

        XCTAssertNoThrow(try book.validateForUpdate(), "Correct title generates validation error")
    }

    override func tearDown() {
        mockCoreDataStack.flushData()
        super.tearDown()
    }

    // MARK: - Helpers

    private func insertBookItem(title: String,
                                googleBooksId: String? = nil,
                                manualId: String? = nil,
                                isbn: String? = nil,
                                authors: [Author],
                                readState: BookReadState = .toRead) -> Book? {
        let book = NSEntityDescription.insertNewObject(forEntityName: "Book", into: mockCoreDataStack.mainContext) as! Book
        book.title = title
        book.googleBooksId = googleBooksId
        book.manualBookId = manualId
        book.readState = readState
        if let currentIsbn = isbn {
            book.isbn13 = isbnNumber(from: currentIsbn)
        }
        book.setAuthors(authors)

        return book
    }

    private func isbnNumber(from isbnString: String) -> NSNumber? {
        guard let isbnInt = ISBN13(isbnString)?.int else {
            return nil
        }

        return NSNumber(value: isbnInt)
    }
}
