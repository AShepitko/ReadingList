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

    static let validIsbn = "9789604533084"

    var mockCoreDataStack = MockCoreDataStack()

    // MARK: - Initialize book

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

    func testBookPopulatedWithFetchResult() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        let fetchResult = FetchResult(fromSearchResult: SearchResult(id: UUID().uuidString, title: "Test", authors: ["test.author"]))
        fetchResult.isbn13 = ISBN13(BookModelTests.validIsbn)
        fetchResult.pageCount = 100
        fetchResult.subjects = ["test", "subject"]
        fetchResult.languageCode = "en"

        sut.populate(fromFetchResult: fetchResult)

        assertBookInfo(sut, matchingFetchResult: fetchResult)
    }

    func testBookPopulatedWithSearchResult() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        let searchResult = SearchResult(id: UUID().uuidString, title: "Test", authors: ["test.author"])
        searchResult.isbn13 = BookModelTests.validIsbn

        sut.populate(fromSearchResult: searchResult)

        assertBookInfo(sut, matchingSearchResult: searchResult)
    }

    func testBookPopulatedWithSearchResultSetsCoverImage() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        let searchResult = SearchResult(id: UUID().uuidString, title: "Test", authors: ["test.author"])
        let coverImage = Data()

        sut.populate(fromSearchResult: searchResult, withCoverImage: coverImage)

        XCTAssertEqual(sut.coverImage, coverImage)
    }

    func testBookAuthorsPopulateWithSearchResult() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)
        let authors = ["Joan Rowling", "Mark Twen"]
        let searchResult = SearchResult(id: UUID().uuidString, title: "Test", authors: authors)
    
        sut.populate(fromSearchResult: searchResult)

        XCTAssertEqual(sut.authors.map{ $0.displayFirstLast }, authors)
    }

    // MARK: - Fetching books

    func testGetBookByGoogleIdReturnsBook() {
        let bookId = "1"
        let book = createTestBookWithGoogleId(bookId, inContext: mockCoreDataStack.mainContext)

        mockCoreDataStack.mainContext.insert(book)
        mockCoreDataStack.saveMainContext()
        let fetchedBook = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: bookId, isbn: nil)

        XCTAssertEqual(fetchedBook?.googleBooksId, bookId)
    }

    func testGetBookByIsdnReturnsBook() {
        let bookIsbn = "9780451524935"
        let book = createTestBookWithIsbn(bookIsbn, inContext: mockCoreDataStack.mainContext)

        mockCoreDataStack.mainContext.insert(book)
        mockCoreDataStack.saveMainContext()
        let fetchedBook = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: nil, isbn: bookIsbn)

        XCTAssertEqual(fetchedBook?.isbn13, isbnNumber(from: bookIsbn))
    }

    func testGetBookByIncorrectISDNReturnsNil() {
        let bookIsbn: String = "test_isbn"

        let book = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: nil, isbn: bookIsbn)

        XCTAssertNil(book)
    }

    func testGetBookWithEmptyIdsReturnsNil() {
        let book = Book.get(fromContext: mockCoreDataStack.mainContext, googleBooksId: nil, isbn: nil)

        XCTAssertNil(book)
    }

    // MARK: - Book validation

    func testEmptyAuthorsThrowsNoAuthorsError() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.setAuthors([])

        XCTAssertThrowsError(try book.validateForUpdate(), "Empty authors doesn't generate validation error") { error in
            XCTAssertEqual(error as NSError, BookValidationError.noAuthors.NSError())
        }
    }

    func testBookWithAuthorsPassesValidation() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.setAuthors([Author(lastName: "Smith", firstNames: "Jhon")])

        XCTAssertNoThrow(try book.validateForUpdate(), "Book with authors has validation error")
    }

    func testEmptyTitleThrowsValidationError() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.title = String()

        XCTAssertThrowsError(try book.validateForUpdate(), "Incorret title doesn't generate validation error") { error in
            XCTAssertEqual(error as NSError, BookValidationError.missingTitle.NSError())
        }
    }

    func testNotEmptyTitlePassesValidation() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.title = "Test"

        XCTAssertNoThrow(try book.validateForUpdate(), "Correct title generates validation error")
    }

    func testIncorrectIsbnThrowsError() {
        let book = createTestBookWithIsbn(inContext: mockCoreDataStack.mainContext)

        book.isbn13 = NSNumber(value: 1)

        XCTAssertThrowsError(try book.validateForUpdate(), "Incorrect isbn doesn't trigger validation error") { error in
            XCTAssertEqual(error as NSError, BookValidationError.invalidIsbn.NSError())
        }
    }

    func testCorrectIsbnPassesValidation() {
        let book = createTestBookWithIsbn(inContext: mockCoreDataStack.mainContext)

        book.isbn13 = NSNumber(value: 9789604533084)

        XCTAssertNoThrow(try book.validateForUpdate(), "Correct isbn fails validation")
    }

    func testIncorrectLanguageCodeGeneratesError() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.languageCode = "pe"

        XCTAssertThrowsError(try book.validateForUpdate(), "Incorrect language code doesn't trigger validation error") { error in
            XCTAssertEqual(error as NSError, BookValidationError.invalidLanguageCode.NSError())
        }
    }

    func testCorrectLanguageCodePassesValidation() {
        let book = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)

        book.languageCode = "en"

        XCTAssertNoThrow(try book.validateForUpdate(), "Correct language code fails validation")
    }

    // MARK: - Book actions

    func testStartReadingChangeStateToReading() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)

        sut.startReading()

        XCTAssertEqual(sut.readState, .reading)
    }

    func testFinishedBookNotChangeStateWithStartReading() {
        let state: BookReadState = .finished
        let sut = Book(context: mockCoreDataStack.mainContext, readState: state)

        sut.startReading()

        XCTAssertEqual(sut.readState, state)
    }

    func testStartReadingSetsStartReadingDate() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .toRead)

        sut.startReading()

        XCTAssertNotNil(sut.startedReading)
    }

    func testFinishReadingChangeStateToFinished() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .reading)

        sut.finishReading()

        XCTAssertEqual(sut.readState, .finished)
    }

    func testNotReadBookNotChangeStateWithFinishReading() {
        let state: BookReadState = .toRead
        let sut = Book(context: mockCoreDataStack.mainContext, readState: state)

        sut.finishReading()

        XCTAssertEqual(sut.readState, state)
    }

    func testFinishReafingSetsFinishReadingDate() {
        let sut = Book(context: mockCoreDataStack.mainContext, readState: .reading)

        sut.finishReading()

        XCTAssertNotNil(sut.finishedReading)
    }
    
    // MARK: - Deletion

    func testBookDeletionDeleteSubjects() {
        let sut = createTestBookWithGoogleId(inContext: mockCoreDataStack.mainContext)
        let subjetsNames = ["test", "book"]
        let subjects = Set(subjetsNames.map { Subject.getOrCreate(inContext: mockCoreDataStack.mainContext, withName: $0) })
        sut.subjects = subjects

        mockCoreDataStack.mainContext.insert(sut)
        mockCoreDataStack.saveMainContext()
        sut.delete()

        subjects.forEach { XCTAssertTrue($0.isDeleted) }
    }

    // MARK: - Tear down

    override func tearDown() {
        mockCoreDataStack.flushData()
        super.tearDown()
    }

    // MARK: - Helpers

    private func assertBookInfo(_ book: Book, matchingFetchResult fetchResult: FetchResult, file: StaticString = #file, line: UInt = #line) {
        guard book.googleBooksId == fetchResult.id,
              book.title == fetchResult.title,
              book.bookDescription == fetchResult.description,
              book.languageCode == fetchResult.languageCode,
              book.publicationDate == fetchResult.publishedDate,
              book.coverImage == fetchResult.coverImage,
              book.pageCount?.intValue == fetchResult.pageCount,
              book.isbn13?.int64Value == fetchResult.isbn13?.int,
              book.subjects.count == fetchResult.subjects.count,
              book.authors.count == fetchResult.authors.count else {
            XCTFail("Book doesn't match fetch result", file: file, line: line)
            return
        }
    }
    
    private func assertBookInfo(_ book: Book, matchingSearchResult searchResult: SearchResult, file: StaticString = #file, line: UInt = #line) {
        guard book.googleBooksId == searchResult.id,
              book.title == searchResult.title,
              book.authors.count == searchResult.authors.count else {
            XCTFail("Book doesn't match fetch result", file: file, line: line)
            return
        }
        
        if let searchResultIsbn = searchResult.isbn13, let searchIsbn = isbnNumber(from: searchResultIsbn) {
            XCTAssertEqual(book.isbn13, searchIsbn, file: file, line: line)
        }
    }

    private func createTestBookWithIsbn(_ isbn: String = validIsbn,
                                        inContext context: NSManagedObjectContext) -> Book {
        let book = Book(context: context, readState: .toRead)
        book.manualBookId = UUID().uuidString
        book.title = "Harry Potter"
        book.isbn13 = isbnNumber(from: isbn)
        book.setAuthors([Author(lastName: "Rowling", firstNames: "Joan")])
        book.languageCode = "en"

        return book
    }

    private func createTestBookWithGoogleId(_ googleId: String = UUID().uuidString,
                                            inContext context: NSManagedObjectContext) -> Book {
        let book = Book(context: context, readState: .toRead)
        book.googleBooksId = googleId
        book.title = "Harry Potter"
        book.setAuthors([Author(lastName: "Rowling", firstNames: "Joan")])
        book.languageCode = "en"

        return book
    }

    private func isbnNumber(from isbnString: String) -> NSNumber? {
        guard let isbnInt = ISBN13(isbnString)?.int else {
            return nil
        }

        return NSNumber(value: isbnInt)
    }
}
