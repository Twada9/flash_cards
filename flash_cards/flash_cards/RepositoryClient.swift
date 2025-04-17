import Foundation
import ComposableArchitecture

// リポジトリへのアクセスを提供するクライアント
struct RepositoryClient {
    var deckRepository: DeckRepositoryProtocol
    var wordRepository: WordRepositoryProtocol
    
    // デッキ関連の操作
    var saveDeck: @Sendable (Deck) async throws -> Void
    var getAllDecks: @Sendable () async -> [Deck]
    var getDeck: @Sendable (UUID) async -> Deck?
    var deleteDeck: @Sendable (UUID) async throws -> Void
    var updateDeck: @Sendable (Deck) async throws -> Void
    var addWordToDeck: @Sendable (UUID, Word) async throws -> Void
    var removeWordFromDeck: @Sendable (UUID, UUID) async throws -> Void
    
    // 単語関連の操作
    var saveWord: @Sendable (Word) async throws -> Void
    var getWords: @Sendable (UUID) async -> [Word]
    var deleteWord: @Sendable (UUID) async throws -> Void
    var updateWord: @Sendable (Word) async throws -> Void
}

extension RepositoryClient: DependencyKey {
    static var liveValue: RepositoryClient {
        do {
            let deckRepo = try DeckRepository()
            let wordRepo = try WordRepository()
            
            return RepositoryClient(
                deckRepository: deckRepo,
                wordRepository: wordRepo,
                saveDeck: { deck in
                    try await Task {
                        try deckRepo.saveDeck(deck)
                    }.value
                },
                getAllDecks: {
                    await Task {
                        deckRepo.getAllDecks()
                    }.value
                },
                getDeck: { id in
                    await Task {
                        deckRepo.getDeck(id: id)
                    }.value
                },
                deleteDeck: { id in
                    try await Task {
                        try deckRepo.deleteDeck(id: id)
                    }.value
                },
                updateDeck: { deck in
                    try await Task {
                        try deckRepo.updateDeck(deck)
                    }.value
                },
                addWordToDeck: { deckId, word in
                    try await Task {
                        try deckRepo.addWordToDeck(deckId: deckId, word: word)
                    }.value
                },
                removeWordFromDeck: { deckId, wordId in
                    try await Task {
                        try deckRepo.removeWordFromDeck(deckId: deckId, wordId: wordId)
                    }.value
                },
                saveWord: { word in
                    try await Task {
                        try wordRepo.saveWord(word)
                    }.value
                },
                getWords: { deckId in
                    await Task {
                        wordRepo.getWords(forDeckId: deckId)
                    }.value
                },
                deleteWord: { id in
                    try await Task {
                        try wordRepo.deleteWord(id: id)
                    }.value
                },
                updateWord: { word in
                    try await Task {
                        try wordRepo.updateWord(word)
                    }.value
                }
            )
        } catch {
            fatalError("Failed to initialize repositories: \(error)")
        }
    }
    
    // テスト用のモックリポジトリクライアント
    static var testValue: RepositoryClient {
        RepositoryClient(
            deckRepository: MockDeckRepository(),
            wordRepository: MockWordRepository(),
            saveDeck: { _ in },
            getAllDecks: { [] },
            getDeck: { _ in nil },
            deleteDeck: { _ in },
            updateDeck: { _ in },
            addWordToDeck: { _, _ in },
            removeWordFromDeck: { _, _ in },
            saveWord: { _ in },
            getWords: { _ in [] },
            deleteWord: { _ in },
            updateWord: { _ in }
        )
    }
}

// TCAの依存関係としてリポジトリクライアントを登録
extension DependencyValues {
    var repositoryClient: RepositoryClient {
        get { self[RepositoryClient.self] }
        set { self[RepositoryClient.self] = newValue }
    }
}

// モックリポジトリの実装 (テスト用)
class MockDeckRepository: DeckRepositoryProtocol {
    var decks: [Deck] = []
    
    func saveDeck(_ deck: Deck) throws {
        decks.append(deck)
    }
    
    func getAllDecks() -> [Deck] {
        return decks
    }
    
    func getDeck(id: UUID) -> Deck? {
        return decks.first(where: { $0.id == id })
    }
    
    func deleteDeck(id: UUID) throws {
        decks.removeAll(where: { $0.id == id })
    }
    
    func updateDeck(_ deck: Deck) throws {
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
        }
    }
    
    func addWordToDeck(deckId: UUID, word: Word) throws {
        // モック実装なので実際のデータ操作はしない
    }
    
    func removeWordFromDeck(deckId: UUID, wordId: UUID) throws {
        // モック実装なので実際のデータ操作はしない
    }
}

class MockWordRepository: WordRepositoryProtocol {
    var words: [Word] = []
    
    func saveWord(_ word: Word) throws {
        words.append(word)
    }
    
    func getWords(forDeckId deckId: UUID) -> [Word] {
        return words
    }
    
    func deleteWord(id: UUID) throws {
        words.removeAll(where: { $0.id == id })
    }
    
    func updateWord(_ word: Word) throws {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        }
    }
}