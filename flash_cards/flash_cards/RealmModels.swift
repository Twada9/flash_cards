import Foundation
import RealmSwift
import ComposableArchitecture

// RealmConfigurationをDependencyとして提供
struct RealmConfigurationClient {
    var getConfiguration: @Sendable () -> Realm.Configuration
    var getRealm: @Sendable () throws -> Realm
}

extension RealmConfigurationClient: DependencyKey {
    static let liveValue: RealmConfigurationClient = {
        let configuration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: RealmDeck.className()) { _, _ in }
                    migration.enumerateObjects(ofType: RealmWord.className()) { _, _ in }
                }
            },
            objectTypes: [RealmWord.self, RealmDeck.self]
        )
        
        // デフォルト設定を一度だけ設定
        Realm.Configuration.defaultConfiguration = configuration
        
        return RealmConfigurationClient(
            getConfiguration: { configuration },
            getRealm: { try Realm(configuration: configuration) }
        )
    }()
    
    static let testValue = RealmConfigurationClient(
        getConfiguration: {
            Realm.Configuration(
                inMemoryIdentifier: "test-realm",
                objectTypes: [RealmWord.self, RealmDeck.self]
            )
        },
        getRealm: {
            try Realm(configuration: Realm.Configuration(
                inMemoryIdentifier: "test-realm",
                objectTypes: [RealmWord.self, RealmDeck.self]
            ))
        }
    )
}

extension DependencyValues {
    var realmConfiguration: RealmConfigurationClient {
        get { self[RealmConfigurationClient.self] }
        set { self[RealmConfigurationClient.self] = newValue }
    }
}

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
