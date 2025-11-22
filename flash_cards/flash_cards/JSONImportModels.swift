//
//  JSONImportModels.swift
//  flash_cards
//
//  Created for JSON import functionality
//

import Foundation

// JSON互換のDeckモデル - 単語を含むことができる
struct DeckJSON: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var words: [WordJSON]?
    
    init(id: UUID = UUID(), title: String, words: [WordJSON]? = nil) {
        self.id = id
        self.title = title
        self.words = words
    }
    
    // 既存のDeckモデルに変換
    func toDeck() -> Deck {
        return Deck(id: id, title: title)
    }
    
    // 既存のDeckモデルから作成
    static func from(deck: Deck, words: [Word] = []) -> DeckJSON {
        return DeckJSON(
            id: deck.id,
            title: deck.title,
            words: words.isEmpty ? nil : words.map { WordJSON.from(word: $0) }
        )
    }
}

// JSON互換のWordモデル
struct WordJSON: Codable, Identifiable, Equatable {
    var id: UUID
    var term: String
    var definition: String
    
    init(id: UUID = UUID(), term: String, definition: String) {
        self.id = id
        self.term = term
        self.definition = definition
    }
    
    // 既存のWordモデルに変換
    func toWord() -> Word {
        return Word(id: id, term: term, definition: definition)
    }
    
    // 既存のWordモデルから作成
    static func from(word: Word) -> WordJSON {
        return WordJSON(id: word.id, term: word.term, definition: word.definition)
    }
}

// JSON import/export時のエラー
enum JSONImportError: LocalizedError {
    case invalidJSON
    case emptyData
    case decodingError(String)
    case encodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "無効なJSON形式です"
        case .emptyData:
            return "データが空です"
        case .decodingError(let message):
            return "データの読み込みに失敗しました: \(message)"
        case .encodingError(let message):
            return "データの書き出しに失敗しました: \(message)"
        }
    }
}
