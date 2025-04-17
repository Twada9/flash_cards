import Foundation
import RealmSwift

struct DemoData {
    static let decks: [Deck] = [
        Deck(id: UUID(), title: "基本英単語"),
        Deck(id: UUID(), title: "TOEIC頻出単語"),
        Deck(id: UUID(), title: "プログラミング用語")
    ]
    
    static let words: [(deckIndex: Int, words: [Word])] = [
        (0, [
            Word(term: "Apple", definition: "りんご"),
            Word(term: "Banana", definition: "バナナ"),
            Word(term: "Cat", definition: "猫"),
            Word(term: "Dog", definition: "犬"),
            Word(term: "Elephant", definition: "象"),
            Word(term: "Fish", definition: "魚"),
            Word(term: "Giraffe", definition: "キリン"),
            Word(term: "House", definition: "家"),
            Word(term: "Ice cream", definition: "アイスクリーム"),
            Word(term: "Juice", definition: "ジュース")
        ]),
        (1, [
            Word(term: "implement", definition: "実装する"),
            Word(term: "revenue", definition: "収益"),
            Word(term: "negotiate", definition: "交渉する"),
            Word(term: "delegate", definition: "委任する"),
            Word(term: "initiative", definition: "主導権"),
            Word(term: "facilitate", definition: "促進する"),
            Word(term: "compliance", definition: "法令順守"),
            Word(term: "deadline", definition: "締切"),
            Word(term: "expertise", definition: "専門知識"),
            Word(term: "optimize", definition: "最適化する")
        ]),
        (2, [
            Word(term: "API", definition: "アプリケーションプログラミングインターフェース"),
            Word(term: "Git", definition: "分散型バージョン管理システム"),
            Word(term: "HTTP", definition: "ハイパーテキスト転送プロトコル"),
            Word(term: "JSON", definition: "JavaScript Object Notation"),
            Word(term: "REST", definition: "Representational State Transfer"),
            Word(term: "SQL", definition: "構造化照会言語"),
            Word(term: "UI/UX", definition: "ユーザーインターフェース/ユーザーエクスペリエンス"),
            Word(term: "Variable", definition: "変数"),
            Word(term: "Function", definition: "関数"),
            Word(term: "Object", definition: "オブジェクト")
        ])
    ]
    
    static func insertDemoDataIfNeeded() async throws {
        let client = RepositoryClient.liveValue
        
        print("[DemoData] Starting demo data insertion check...")
        
        // 既存のデッキをチェック
        let existingDecks = await client.getAllDecks()
        print("[DemoData] Found \(existingDecks.count) existing decks")
        
        if !existingDecks.isEmpty {
            print("[DemoData] Decks already exist, skipping demo data insertion")
            return // デモデータが既に存在する場合は何もしない
        }
        
        print("[DemoData] No existing decks found, inserting demo data...")
        
        do {
            // デッキを作成
            for deck in decks {
                print("[DemoData] Creating deck: \(deck.title)")
                try await client.saveDeck(deck)
            }
            
            // 単語を追加
            for (deckIndex, words) in words {
                let deck = decks[deckIndex]
                print("[DemoData] Adding \(words.count) words to deck: \(deck.title)")
                for word in words {
                    try await client.addWordToDeck(deck.id, word)
                }
            }
            print("[DemoData] Demo data insertion completed successfully")
        } catch {
            print("[DemoData] Error inserting demo data: \(error)")
            throw error
        }
    }
}