//
//  JSONImportService.swift
//  flash_cards
//
//  JSON import/export service
//

import Foundation
import ComposableArchitecture

// JSON importサービス
struct JSONImportService {
    
    // JSON文字列からDecksをインポート（単語付き）
    static func importDeck(from jsonString: String) throws -> DeckJSON {
        guard !jsonString.isEmpty else {
            throw JSONImportError.emptyData
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JSONImportError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        do {
            let deck = try decoder.decode(DeckJSON.self, from: jsonData)
            return deck
        } catch {
            throw JSONImportError.decodingError(error.localizedDescription)
        }
    }
    
    // 複数のDecksをインポート
    static func importDecks(from jsonString: String) throws -> [DeckJSON] {
        guard !jsonString.isEmpty else {
            throw JSONImportError.emptyData
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JSONImportError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        do {
            let decks = try decoder.decode([DeckJSON].self, from: jsonData)
            return decks
        } catch {
            throw JSONImportError.decodingError(error.localizedDescription)
        }
    }
    
    // 単語リストをインポート
    static func importWords(from jsonString: String) throws -> [WordJSON] {
        guard !jsonString.isEmpty else {
            throw JSONImportError.emptyData
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw JSONImportError.invalidJSON
        }
        
        let decoder = JSONDecoder()
        do {
            let words = try decoder.decode([WordJSON].self, from: jsonData)
            return words
        } catch {
            throw JSONImportError.decodingError(error.localizedDescription)
        }
    }
    
    // DeckをJSON文字列にエクスポート
    static func exportDeck(_ deck: DeckJSON) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(deck)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw JSONImportError.invalidJSON
            }
            return jsonString
        } catch {
            throw JSONImportError.encodingError(error.localizedDescription)
        }
    }
    
    // Decks配列をJSON文字列にエクスポート
    static func exportDecks(_ decks: [DeckJSON]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(decks)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw JSONImportError.invalidJSON
            }
            return jsonString
        } catch {
            throw JSONImportError.encodingError(error.localizedDescription)
        }
    }
    
    // Words配列をJSON文字列にエクスポート
    static func exportWords(_ words: [WordJSON]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let jsonData = try encoder.encode(words)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw JSONImportError.invalidJSON
            }
            return jsonString
        } catch {
            throw JSONImportError.encodingError(error.localizedDescription)
        }
    }
}
