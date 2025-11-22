import Foundation
import RealmSwift
import ComposableArchitecture

// WordRepository - 単語の保存と取得を担当
protocol WordRepositoryProtocol {
    func saveWord(_ word: Word) throws
    func getWords(forDeckId deckId: UUID) -> [Word]
    func deleteWord(id: UUID) throws
    func updateWord(_ word: Word) throws
}

class WordRepository: WordRepositoryProtocol {
    @Dependency(\.realmConfiguration) var realmConfig
    
    private func getRealm() throws -> Realm {
        return try realmConfig.getRealm()
    }
    
    func saveWord(_ word: Word) throws {
        let realm = try getRealm()
        let realmWord = RealmWord(word: word)
        try realm.write {
            realm.add(realmWord, update: .modified)
        }
    }
    
    func getWords(forDeckId deckId: UUID) -> [Word] {
        print("[WordRepository] Getting words for deck: \(deckId)")
        guard let realm = try? getRealm() else {
            print("[WordRepository] Failed to get Realm instance")
            return []
        }
        
        guard let realmDeck = realm.object(ofType: RealmDeck.self, forPrimaryKey: deckId) else {
            print("[WordRepository] Deck not found: \(deckId)")
            return []
        }
        
        // スレッドセーフな方法でデータをコピー
        let words = Array(realmDeck.words.map { $0.toWord() })
        print("[WordRepository] Found \(words.count) words")
        return words
    }
    
    func deleteWord(id: UUID) throws {
        let realm = try getRealm()
        guard let realmWord = realm.object(ofType: RealmWord.self, forPrimaryKey: id) else {
            return
        }
        
        try realm.write {
            realm.delete(realmWord)
        }
    }
    
    func updateWord(_ word: Word) throws {
        let realm = try getRealm()
        
        if let existingWord = realm.object(ofType: RealmWord.self, forPrimaryKey: word.id) {
            try realm.write {
                existingWord.term = word.term
                existingWord.definition = word.definition
            }
            print("[WordRepository] Word updated successfully: \(word.id)")
        } else {
            // 存在しない場合は新規作成（通常は起きないはずだが念のため）
            print("[WordRepository] Warning: Word not found for update: \(word.id)")
            let realmWord = RealmWord(word: word)
            try realm.write {
                realm.add(realmWord, update: .modified)
            }
        }
    }
}

// DeckRepository - デッキの保存と取得を担当
protocol DeckRepositoryProtocol {
    func saveDeck(_ deck: Deck) throws
    func getAllDecks() -> [Deck]
    func getDeck(id: UUID) -> Deck?
    func deleteDeck(id: UUID) throws
    func updateDeck(_ deck: Deck) throws
    func addWordToDeck(deckId: UUID, word: Word) throws
    func removeWordFromDeck(deckId: UUID, wordId: UUID) throws
    func importDeckFromJSON(_ deckJSON: DeckJSON) throws
    func importDecksFromJSON(_ decksJSON: [DeckJSON]) throws
}

class DeckRepository: DeckRepositoryProtocol {
    @Dependency(\.realmConfiguration) var realmConfig
    
    private func getRealm() throws -> Realm {
        return try realmConfig.getRealm()
    }
    
    func saveDeck(_ deck: Deck) throws {
        let realm = try getRealm()
        let realmDeck = RealmDeck(deck: deck)
        try realm.write {
            realm.add(realmDeck, update: .modified)
        }
    }
    
    func getAllDecks() -> [Deck] {
        guard let realm = try? getRealm() else { return [] }
        // スレッドセーフな方法でデータをコピー
        let decks = Array(realm.objects(RealmDeck.self)).map { $0.toDeck() }
        return decks
    }
    
    func getDeck(id: UUID) -> Deck? {
        guard let realm = try? getRealm(),
              let realmDeck = realm.object(ofType: RealmDeck.self, forPrimaryKey: id) else {
            return nil
        }
        return realmDeck.toDeck()
    }
    
    func deleteDeck(id: UUID) throws {
        let realm = try getRealm()
        guard let realmDeck = realm.object(ofType: RealmDeck.self, forPrimaryKey: id) else {
            return
        }
        
        try realm.write {
            realm.delete(realmDeck)
        }
    }
    
    func updateDeck(_ deck: Deck) throws {
        let realm = try getRealm()
        let realmDeck = RealmDeck(deck: deck)
        try realm.write {
            realm.add(realmDeck, update: .modified)
        }
    }
    
    func addWordToDeck(deckId: UUID, word: Word) throws {
        print("[DeckRepository] Adding word to deck: \(deckId)")
        let realm = try getRealm()
        guard let realmDeck = realm.object(ofType: RealmDeck.self, forPrimaryKey: deckId) else {
            print("[DeckRepository] Deck not found: \(deckId)")
            return
        }
        
        let realmWord = RealmWord(word: word)
        
        try realm.write {
            print("[DeckRepository] Adding word: \(word.term)")
            realm.add(realmWord, update: .modified)
            realmDeck.words.append(realmWord)
        }
        print("[DeckRepository] Word added successfully")
    }
    
    func removeWordFromDeck(deckId: UUID, wordId: UUID) throws {
        let realm = try getRealm()
        guard let realmDeck = realm.object(ofType: RealmDeck.self, forPrimaryKey: deckId),
              let wordIndex = realmDeck.words.firstIndex(where: { $0.id == wordId }) else {
            return
        }
        
        try realm.write {
            realmDeck.words.remove(at: wordIndex)
        }
    }
    
    // JSONからDeckと単語をインポート
    func importDeckFromJSON(_ deckJSON: DeckJSON) throws {
        let realm = try getRealm()
        
        // Deckを作成
        let realmDeck = RealmDeck()
        realmDeck.id = deckJSON.id
        realmDeck.title = deckJSON.title
        
        try realm.write {
            // Deckを保存
            realm.add(realmDeck, update: .modified)
            
            // 単語があれば追加
            if let words = deckJSON.words {
                for wordJSON in words {
                    let realmWord = RealmWord()
                    realmWord.id = wordJSON.id
                    realmWord.term = wordJSON.term
                    realmWord.definition = wordJSON.definition
                    
                    realm.add(realmWord, update: .modified)
                    realmDeck.words.append(realmWord)
                }
            }
        }
    }
    
    // 複数のDecksをJSONからインポート
    func importDecksFromJSON(_ decksJSON: [DeckJSON]) throws {
        for deckJSON in decksJSON {
            try importDeckFromJSON(deckJSON)
        }
    }
}
