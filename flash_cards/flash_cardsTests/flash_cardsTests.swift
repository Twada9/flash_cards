//
//  flash_cardsTests.swift
//  flash_cardsTests
//
//  Created by wada on 2025/02/16.
//

import XCTest
import ComposableArchitecture
@testable import flash_cards

final class flash_cardsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

// MARK: - JSON Import Tests

final class JSONImportTests: XCTestCase {
    
    // MARK: - WordJSON Tests
    
    func testWordJSONEncoding() throws {
        let word = WordJSON(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            term: "Hello",
            definition: "こんにちは"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(word)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("Hello"))
        XCTAssertTrue(jsonString.contains("こんにちは"))
    }
    
    func testWordJSONDecoding() throws {
        let jsonString = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "term": "Hello",
            "definition": "こんにちは"
        }
        """
        
        let word = try JSONImportService.importWords(from: "[\(jsonString)]").first
        
        XCTAssertNotNil(word)
        XCTAssertEqual(word?.term, "Hello")
        XCTAssertEqual(word?.definition, "こんにちは")
    }
    
    func testWordJSONToWord() throws {
        let wordJSON = WordJSON(
            id: UUID(),
            term: "Test",
            definition: "テスト"
        )
        
        let word = wordJSON.toWord()
        
        XCTAssertEqual(word.id, wordJSON.id)
        XCTAssertEqual(word.term, "Test")
        XCTAssertEqual(word.definition, "テスト")
    }
    
    func testWordToWordJSON() throws {
        let word = Word(id: UUID(), term: "Swift", definition: "スイフト")
        let wordJSON = WordJSON.from(word: word)
        
        XCTAssertEqual(wordJSON.id, word.id)
        XCTAssertEqual(wordJSON.term, "Swift")
        XCTAssertEqual(wordJSON.definition, "スイフト")
    }
    
    // MARK: - DeckJSON Tests
    
    func testDeckJSONEncoding() throws {
        let deck = DeckJSON(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789012")!,
            title: "English Vocabulary",
            words: [
                WordJSON(id: UUID(), term: "Hello", definition: "こんにちは"),
                WordJSON(id: UUID(), term: "World", definition: "世界")
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(deck)
        let jsonString = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(jsonString.contains("English Vocabulary"))
        XCTAssertTrue(jsonString.contains("Hello"))
        XCTAssertTrue(jsonString.contains("World"))
    }
    
    func testDeckJSONDecoding() throws {
        let jsonString = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "English Vocabulary",
            "words": [
                {
                    "id": "87654321-1234-1234-1234-123456789012",
                    "term": "Hello",
                    "definition": "こんにちは"
                }
            ]
        }
        """
        
        let deck = try JSONImportService.importDeck(from: jsonString)
        
        XCTAssertEqual(deck.title, "English Vocabulary")
        XCTAssertEqual(deck.words?.count, 1)
        XCTAssertEqual(deck.words?.first?.term, "Hello")
    }
    
    func testDeckJSONWithoutWords() throws {
        let jsonString = """
        {
            "id": "12345678-1234-1234-1234-123456789012",
            "title": "Empty Deck"
        }
        """
        
        let deck = try JSONImportService.importDeck(from: jsonString)
        
        XCTAssertEqual(deck.title, "Empty Deck")
        XCTAssertNil(deck.words)
    }
    
    func testDeckJSONToDeck() throws {
        let deckJSON = DeckJSON(
            id: UUID(),
            title: "Test Deck",
            words: nil
        )
        
        let deck = deckJSON.toDeck()
        
        XCTAssertEqual(deck.id, deckJSON.id)
        XCTAssertEqual(deck.title, "Test Deck")
    }
    
    func testDeckToDeckJSON() throws {
        let deck = Deck(id: UUID(), title: "Swift Deck")
        let words = [
            Word(id: UUID(), term: "var", definition: "変数"),
            Word(id: UUID(), term: "let", definition: "定数")
        ]
        
        let deckJSON = DeckJSON.from(deck: deck, words: words)
        
        XCTAssertEqual(deckJSON.id, deck.id)
        XCTAssertEqual(deckJSON.title, "Swift Deck")
        XCTAssertEqual(deckJSON.words?.count, 2)
    }
    
    // MARK: - JSONImportService Tests
    
    func testImportMultipleDecks() throws {
        let jsonString = """
        [
            {
                "id": "12345678-1234-1234-1234-123456789012",
                "title": "Deck 1",
                "words": []
            },
            {
                "id": "87654321-1234-1234-1234-123456789012",
                "title": "Deck 2",
                "words": []
            }
        ]
        """
        
        let decks = try JSONImportService.importDecks(from: jsonString)
        
        XCTAssertEqual(decks.count, 2)
        XCTAssertEqual(decks[0].title, "Deck 1")
        XCTAssertEqual(decks[1].title, "Deck 2")
    }
    
    func testImportEmptyDataThrowsError() {
        XCTAssertThrowsError(try JSONImportService.importDeck(from: "")) { error in
            XCTAssertTrue(error is JSONImportError)
            if case JSONImportError.emptyData = error {
                // Expected error
            } else {
                XCTFail("Expected JSONImportError.emptyData")
            }
        }
    }
    
    func testImportInvalidJSONThrowsError() {
        let invalidJSON = "{invalid json"
        
        XCTAssertThrowsError(try JSONImportService.importDeck(from: invalidJSON)) { error in
            XCTAssertTrue(error is JSONImportError)
        }
    }
    
    func testExportDeck() throws {
        let deck = DeckJSON(
            id: UUID(),
            title: "Export Test",
            words: [
                WordJSON(id: UUID(), term: "A", definition: "エー")
            ]
        )
        
        let jsonString = try JSONImportService.exportDeck(deck)
        
        XCTAssertTrue(jsonString.contains("Export Test"))
        XCTAssertTrue(jsonString.contains("\"A\""))
        XCTAssertTrue(jsonString.contains("エー"))
    }
    
    func testExportWords() throws {
        let words = [
            WordJSON(id: UUID(), term: "Apple", definition: "りんご"),
            WordJSON(id: UUID(), term: "Banana", definition: "バナナ")
        ]
        
        let jsonString = try JSONImportService.exportWords(words)
        
        XCTAssertTrue(jsonString.contains("Apple"))
        XCTAssertTrue(jsonString.contains("Banana"))
        XCTAssertTrue(jsonString.contains("りんご"))
        XCTAssertTrue(jsonString.contains("バナナ"))
    }
    
    // MARK: - Round-trip Tests
    
    func testDeckRoundTrip() throws {
        let originalDeck = DeckJSON(
            id: UUID(),
            title: "Round Trip Test",
            words: [
                WordJSON(id: UUID(), term: "Test", definition: "テスト"),
                WordJSON(id: UUID(), term: "Data", definition: "データ")
            ]
        )
        
        // Export to JSON
        let jsonString = try JSONImportService.exportDeck(originalDeck)
        
        // Import from JSON
        let importedDeck = try JSONImportService.importDeck(from: jsonString)
        
        XCTAssertEqual(originalDeck.id, importedDeck.id)
        XCTAssertEqual(originalDeck.title, importedDeck.title)
        XCTAssertEqual(originalDeck.words?.count, importedDeck.words?.count)
    }
}

