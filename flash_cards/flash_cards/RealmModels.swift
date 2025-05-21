import Foundation
import RealmSwift

// Realmで使用するモデルクラス
class RealmWord: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var term: String = ""
    @Persisted var definition: String = ""
    @Persisted(originProperty: "words") var assignee: LinkingObjects<RealmDeck>
    
    convenience init(word: Word) {
        self.init()
        self.id = word.id
        self.term = word.term
        self.definition = word.definition
    }
    
    func toWord() -> Word {
        // スレッドセーフなコピーを作成
        let frozenObject = self.freeze()
        return Word(id: frozenObject.id, term: frozenObject.term, definition: frozenObject.definition)
    }
}

class RealmDeck: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var title: String = ""
    @Persisted var words = List<RealmWord>()
    
    convenience init(deck: Deck) {
        self.init()
        self.id = deck.id
        self.title = deck.title
    }
    
    func toDeck() -> Deck {
        // スレッドセーフなコピーを作成
        let frozenObject = self.freeze()
        return Deck(id: frozenObject.id, title: frozenObject.title)
    }
    
    func toFullDeck() -> Deck {
        // スレッドセーフなコピーを作成
        let frozenObject = self.freeze()
        let deck = Deck(id: frozenObject.id, title: frozenObject.title)
        print("[RealmDeck] Converting deck with \(frozenObject.words.count) words")
        return deck
    }
}
