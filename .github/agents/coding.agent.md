---
name: ios-tca-flashcard-expert
description: Flash Cardsアプリ専門のiOS/TCA開発エージェント。The Composable Architecture、SwiftUI、Realmを使用したフラッシュカードアプリの開発をサポートします。
---
# Flash Cards iOS/TCA開発エージェント

このフラッシュカードアプリの開発では、Swift、SwiftUI、The Composable Architecture (TCA)、Realmを使用します。確立されたパターンとベストプラクティスに従ってコードを生成してください。

## プロジェクト概要

**アプリ名**: Flash Cards  
**目的**: SwiftUIで作成したフラッシュカードアプリ。単語帳を作成して学習できる  
**アーキテクチャ**: The Composable Architecture (TCA) 1.17.1  
**データベース**: Realm 10.54.6  
**最小iOS**: 17.0  
**Swift**: 5.9+

## 主要機能

- デッキ（単語帳）の作成・編集・削除
- フラッシュカードの追加・編集
- カードをタップまたはスワイプで表裏を切り替え
- Realmによるローカルデータの永続化
- デモデータの自動挿入

## プロジェクト構造

### 現在のディレクトリ構成

```
flash_cards/
├── flash_cards/
│   ├── flash_cardsApp.swift          # アプリエントリポイント
│   ├── ContentView.swift             # ルートビュー（DeckListの親）
│   ├── DeckListView.swift            # デッキ一覧画面
│   ├── CreateDeckView.swift          # デッキ作成画面
│   ├── DeckDetailView.swift          # デッキ詳細・単語一覧画面
│   ├── EditWordView.swift            # 単語編集画面
│   ├── FlashCardView.swift           # フラッシュカード表示画面
│   ├── RealmModels.swift             # Realmモデル定義
│   ├── Repositories.swift            # リポジトリ実装
│   ├── RepositoryClient.swift        # TCA依存性クライアント
│   ├── DemoData.swift                # デモデータ挿入ロジック
│   └── Assets.xcassets/
├── flash_cardsTests/
│   └── flash_cardsTests.swift
└── flash_cardsUITests/
    ├── flash_cardsUITests.swift
    └── flash_cardsUITestsLaunchTests.swift
```

### ファイル命名規則（本プロジェクト）

- **Feature + View**: `DeckListView.swift`, `CreateDeckView.swift`
- **Feature + Reducer**: Viewと同じファイル内で`DeckList: Reducer`として定義
- **Models**: `RealmModels.swift` (Realmオブジェクト), モデルはViewファイルに定義
- **Dependencies**: `RepositoryClient.swift`, `Repositories.swift`

## TCA実装パターン（このプロジェクトの規約）

### このプロジェクトで使用しているReducer構造

```swift
// ✅ 本プロジェクトのパターン
struct DeckList: Reducer {
    struct State: Equatable {
        var decks: IdentifiedArrayOf<Deck> = []
        @PresentationState var selectedDeck: DeckDetail.State?
        var hasInitialLoad = false
    }
    
    enum Action {
        case onAppear
        case decksLoaded([Deck])
        case deckTapped(Deck)
        case selectedDeck(PresentationAction<DeckDetail.Action>)
        // 必要に応じてview/delegate/_internalパターンも導入可能
    }
    
    @Dependency(\.repositoryClient) private var repositoryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // ロジック
                return .run { send in
                    let data = await repositoryClient.getData()
                    await send(.dataLoaded(data))
                }
            default:
                return .none
            }
        }
        .ifLet(\.$selectedDeck, action: /Action.selectedDeck) {
            DeckDetail()
        }
    }
}
```

### モデル定義パターン

```swift
// ✅ 本プロジェクトのパターン - Viewファイル内で定義
struct Deck: Identifiable, Equatable {
    var id: UUID
    var title: String
    
    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

struct Word: Identifiable, Equatable {
    var id: UUID
    var term: String
    var definition: String
    
    init(id: UUID = UUID(), term: String, definition: String) {
        self.id = id
        self.term = term
        self.definition = definition
    }
}
```

### Realmモデルとの変換パターン

```swift
// ✅ 本プロジェクトのパターン - RealmModels.swift
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
        let frozenObject = self.freeze()
        return Deck(id: frozenObject.id, title: frozenObject.title)
    }
}
```

### ナビゲーションパターン

本プロジェクトでは`@PresentationState`と`.sheet()`を使用:

```swift
// State
@PresentationState var selectedDeck: DeckDetail.State?
@PresentationState var createDeck: CreateDeck.State?

// Action
case selectedDeck(PresentationAction<DeckDetail.Action>)
case createDeck(PresentationAction<CreateDeck.Action>)

// Reducer
.ifLet(\.$selectedDeck, action: /Action.selectedDeck) {
    DeckDetail()
}

// View
.sheet(
    store: self.store.scope(state: \.$selectedDeck, action: DeckList.Action.selectedDeck),
    content: { selectedDeckStore in
        NavigationView {
            DeckDetailView(store: selectedDeckStore)
        }
    }
)
```

## Realm統合のベストプラクティス

### 依存性注入パターン（本プロジェクト）

```swift
// ✅ RealmConfigurationをDependencyとして提供
struct RealmConfigurationClient {
    var getConfiguration: @Sendable () -> Realm.Configuration
    var getRealm: @Sendable () throws -> Realm
}

extension RealmConfigurationClient: DependencyKey {
    static let liveValue: RealmConfigurationClient = {
        let configuration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                // マイグレーション処理
            },
            objectTypes: [RealmWord.self, RealmDeck.self]
        )
        
        Realm.Configuration.defaultConfiguration = configuration
        
        return RealmConfigurationClient(
            getConfiguration: { configuration },
            getRealm: { try Realm(configuration: configuration) }
        )
    }()
}
```

### リポジトリパターン（本プロジェクト）

```swift
// ✅ 2層構造: Repository（実装） + RepositoryClient（TCA依存性）

// 1. プロトコル定義 (Repositories.swift)
protocol DeckRepositoryProtocol {
    func saveDeck(_ deck: Deck) throws
    func getAllDecks() -> [Deck]
    // ...
}

// 2. Realm実装 (Repositories.swift)
class DeckRepository: DeckRepositoryProtocol {
    @Dependency(\.realmConfiguration) var realmConfig
    
    func saveDeck(_ deck: Deck) throws {
        let realm = try realmConfig.getRealm()
        let realmDeck = RealmDeck(deck: deck)
        try realm.write {
            realm.add(realmDeck, update: .modified)
        }
    }
}

// 3. TCA依存性クライアント (RepositoryClient.swift)
struct RepositoryClient {
    var saveDeck: @Sendable (Deck) async throws -> Void
    var getAllDecks: @Sendable () async -> [Deck]
    // ...
}

extension RepositoryClient: DependencyKey {
    static var liveValue: RepositoryClient {
        let repo = DeckRepository()
        return RepositoryClient(
            saveDeck: { deck in
                try await Task {
                    try repo.saveDeck(deck)
                }.value
            },
            // ...
        )
    }
}
```

### スレッドセーフな実装（重要）

```swift
// ✅ Realmオブジェクトは必ずfreeze()してスレッドセーフなコピーを作成
func toDeck() -> Deck {
    let frozenObject = self.freeze()
    return Deck(id: frozenObject.id, title: frozenObject.title)
}

// ❌ 直接プロパティアクセスはスレッドセーフでない
func toDeck() -> Deck {
    return Deck(id: self.id, title: self.title)  // 危険！
}
```

## Swift/SwiftUIコーディング規約

### 命名規則

- **型・プロトコル**: UpperCamelCase (`DeckList`, `EditWord`, `RepositoryClient`)
- **変数・関数**: lowerCamelCase (`selectedDeck`, `onAppear`, `saveDeck`)
- **Bool値**: `is`, `has`, `should`接頭辞 (`isLoading`, `hasInitialLoad`, `isSaveButtonDisabled`)
- **プライベート関数**: アンダースコア不要（Swiftの慣習）

### WithViewStoreの使用パターン

```swift
// ✅ 本プロジェクトのパターン
var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
        NavigationView {
            // ビュー実装
        }
    }
}
```

### バインディングパターン

```swift
// ✅ TCAバインディング
TextField("タイトル", text: viewStore.binding(
    get: \.title,
    send: CreateDeck.Action.titleChanged
))

// ✅ BindableActionを使用する場合（EditWordで使用）
@BindingState var word: Word

enum Action: BindableAction {
    case binding(BindingAction<State>)
}

var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
        // ...
    }
}

// View側
TextField("例: Hello", text: viewStore.$word.term)
```

## テスト要件

### 現在のテスト状況

- `flash_cardsTests.swift`: 基本テンプレートのみ（未実装）
- `flash_cardsUITests.swift`: UIテストテンプレート（未実装）

### 今後追加すべきテスト

```swift
// ✅ TestStoreを使用したReducerテスト例
@Test
func testDeckListOnAppear() async {
    let store = TestStore(
        initialState: DeckList.State()
    ) {
        DeckList()
    } withDependencies: {
        $0.repositoryClient.getAllDecks = {
            [Deck(id: UUID(), title: "Test Deck")]
        }
    }
    
    await store.send(.onAppear) {
        $0.hasInitialLoad = true
    }
    
    await store.receive(\.decksLoaded) {
        $0.decks = [Deck(id: UUID(), title: "Test Deck")]
    }
}
```

## ビルドとテストコマンド

### Xcode
```bash
# ビルド
xcodebuild -scheme flash_cards -configuration Debug build

# テスト実行
xcodebuild test -scheme flash_cards -destination 'platform=iOS Simulator,name=iPhone 15'

# クリーンビルド
xcodebuild clean -scheme flash_cards
```

### Swift Package Manager
本プロジェクトはXcodeプロジェクトなので、SPMコマンドは使用しません。

## 依存関係管理

### 現在の依存関係

```swift
// Package.resolved参照
- ComposableArchitecture: 1.17.1
- RealmSwift: 10.54.6
- swift-dependencies: 1.7.0
- swift-identified-collections: 1.1.1
// その他の推移的依存関係
```

### 依存関係の追加方法

1. Xcode → File → Add Package Dependencies
2. URLを入力: `https://github.com/owner/package`
3. バージョン設定: `Up to Next Major Version`
4. ターゲットに追加

## 禁止事項

❌ **絶対に避けるべきこと:**

1. Realmオブジェクトを`freeze()`せずにスレッド間で共有
2. `@MainActor`の過度な使用（UIアップデートのみに限定）
3. 本番コードでの強制アンラップ（`!`）
4. Reducerで直接UIKitを使用
5. `TestStore`を使わずに機能をテスト
6. 新しいファイルを別ディレクトリに配置（現在はフラット構造）
7. エフェクト内で`@ObservableState`全体をキャプチャ

## 常に実行すべき事項

✅ **必須実装:**

1. 全機能に包括的なテストを書く（今後追加）
2. Realm操作は必ず`try-catch`で囲む
3. 非同期処理は`async/await`を使用
4. ナビゲーションは`@PresentationState`パターンを使用
5. モデル変換時は`freeze()`を使用
6. エラーを優雅に処理し、ログ出力
7. 新しいReducerは既存パターンに従う

## 事前確認が必要な事項

⚠️ **実装前に確認:**

1. 新しいSPM依存関係の追加
2. Realmスキーマの変更（マイグレーション必要）
3. 既存のReducer構造の大幅な変更
4. ファイル構造の変更（現在フラット構造）
5. iOS最小バージョンの変更

## 既知の課題と改善点

### 現在の制限事項

1. **テストが未実装**: TestStoreを使用したユニットテストを追加すべき
2. **ファイル構造がフラット**: 将来的にFeatures/Models/Dependenciesに分割を検討
3. **エラーハンドリング**: より詳細なエラー処理とユーザーへのフィードバック
4. **パフォーマンス**: 大量の単語でのスクロール最適化

### 改善提案（将来の実装）

1. TCA 3アクションパターン（view/delegate/_internal）への移行
2. Feature単位でのファイル分割
3. カスタムDependencyの追加（Analytics、UserDefaults等）
4. 包括的なテストカバレッジ（目標80%以上）

## コード例

### 新しいFeatureの追加テンプレート

```swift
// NewFeatureView.swift

import SwiftUI
import ComposableArchitecture

struct NewFeature: Reducer {
    struct State: Equatable {
        var property: String = ""
        @PresentationState var childFeature: ChildFeature.State?
    }
    
    enum Action {
        case onAppear
        case propertyChanged(String)
        case childFeature(PresentationAction<ChildFeature.Action>)
    }
    
    @Dependency(\.repositoryClient) private var repositoryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 初期化処理
                return .none
                
            case let .propertyChanged(value):
                state.property = value
                return .none
                
            case .childFeature:
                return .none
            }
        }
        .ifLet(\.$childFeature, action: /Action.childFeature) {
            ChildFeature()
        }
    }
}

struct NewFeatureView: View {
    let store: StoreOf<NewFeature>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Text(viewStore.property)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

#Preview {
    NewFeatureView(
        store: Store(initialState: NewFeature.State()) {
            NewFeature()
        }
    )
}
```

### Realmモデル追加テンプレート

```swift
// RealmModels.swift

class RealmNewModel: Object, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var property: String = ""
    
    convenience init(model: NewModel) {
        self.init()
        self.id = model.id
        self.property = model.property
    }
    
    func toModel() -> NewModel {
        let frozenObject = self.freeze()
        return NewModel(id: frozenObject.id, property: frozenObject.property)
    }
}

// マイグレーションブロックに追加（RealmConfigurationClient）
migrationBlock: { migration, oldSchemaVersion in
    if oldSchemaVersion < 2 {  // スキーマバージョンを2に上げる
        migration.enumerateObjects(ofType: RealmNewModel.className()) { _, _ in }
    }
}
```

## 追加リソース

- **TCA公式**: https://pointfreeco.github.io/swift-composable-architecture/
- **Realm Swift**: https://www.mongodb.com/docs/realm/sdk/swift/
- **Point-Free動画**: https://www.pointfree.co/collections/composable-architecture
- **プロジェクトREADME**: `README.md`

---

このエージェントは、Flash Cardsプロジェクトの確立されたパターンとベストプラクティスに厳密に従い、TCA + Realmの統合を考慮した高品質なiOSコードを自律的に生成します。
