# JSON Import/Export 機能

Flash CardsアプリにJSONを使用してデッキと単語をインポート・エクスポートする機能が追加されました。

## 概要

この機能により、以下が可能になります：

- JSON形式でデッキと単語のデータをインポート
- 既存のデッキと単語をJSON形式でエクスポート
- AI生成コンテンツの統合
- データのバックアップと共有

## JSON形式

### 単語 (Word)

```json
{
  "id": "12345678-1234-1234-1234-123456789012",
  "term": "Hello",
  "definition": "こんにちは"
}
```

### デッキ (Deck)

```json
{
  "id": "87654321-1234-1234-1234-123456789012",
  "title": "英単語",
  "words": [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "term": "Hello",
      "definition": "こんにちは"
    },
    {
      "id": "22222222-2222-2222-2222-222222222222",
      "term": "World",
      "definition": "世界"
    }
  ]
}
```

### 複数のデッキ

```json
[
  {
    "id": "deck-1-uuid",
    "title": "英単語",
    "words": [...]
  },
  {
    "id": "deck-2-uuid",
    "title": "数学用語",
    "words": [...]
  }
]
```

## 使い方

### UIからインポート

1. デッキ一覧画面で右上のメニューボタン（...）をタップ
2. 「JSONをインポート」を選択
3. JSON形式のデータを貼り付け
4. 「インポート」ボタンをタップ

### プログラムから使用

#### 単一のデッキをインポート

```swift
let jsonString = """
{
  "id": "...",
  "title": "英単語",
  "words": [...]
}
"""

do {
    let deck = try JSONImportService.importDeck(from: jsonString)
    try await repositoryClient.importDeckFromJSON(deck)
} catch {
    print("Import failed: \(error)")
}
```

#### 複数のデッキをインポート

```swift
let jsonString = """
[
  { "id": "...", "title": "Deck 1", "words": [...] },
  { "id": "...", "title": "Deck 2", "words": [...] }
]
"""

do {
    let decks = try JSONImportService.importDecks(from: jsonString)
    try await repositoryClient.importDecksFromJSON(decks)
} catch {
    print("Import failed: \(error)")
}
```

#### デッキをエクスポート

```swift
let deck = Deck(id: UUID(), title: "英単語")
let words = [
    Word(id: UUID(), term: "Hello", definition: "こんにちは")
]

let deckJSON = DeckJSON.from(deck: deck, words: words)

do {
    let jsonString = try JSONImportService.exportDeck(deckJSON)
    print(jsonString)
} catch {
    print("Export failed: \(error)")
}
```

## エラーハンドリング

`JSONImportError` 列挙型を使用してエラーを処理します：

- `.invalidJSON`: 無効なJSON形式
- `.emptyData`: データが空
- `.decodingError(String)`: デコードエラー（詳細メッセージ付き）
- `.encodingError(String)`: エンコードエラー（詳細メッセージ付き）

例：

```swift
do {
    let deck = try JSONImportService.importDeck(from: jsonString)
} catch JSONImportError.emptyData {
    print("データが空です")
} catch JSONImportError.invalidJSON {
    print("無効なJSON形式です")
} catch JSONImportError.decodingError(let message) {
    print("デコードエラー: \(message)")
} catch {
    print("予期しないエラー: \(error)")
}
```

## ファイル構成

- **JSONImportModels.swift**: JSON互換のデータモデル（`DeckJSON`, `WordJSON`）
- **JSONImportService.swift**: JSONのインポート/エクスポート処理
- **ImportJSONView.swift**: JSONインポートUI
- **Repositories.swift**: リポジトリへのJSON import機能追加
- **RepositoryClient.swift**: TCA依存性クライアントへの統合

## テスト

包括的なテストスイートが含まれています：

- エンコード/デコードのテスト
- エラーハンドリングのテスト
- ラウンドトリップ（エクスポート→インポート）テスト
- モデル変換テスト

テストを実行：

```bash
xcodebuild test -scheme flash_cards -destination 'platform=iOS Simulator,name=iPhone 15'
```

## AI統合の例

ChatGPTやClaudeなどのAIに以下のように依頼できます：

```
英語学習用の単語帳を作成してください。
以下のJSON形式で10個の単語を含めてください：

{
  "id": "uuid",
  "title": "基本英単語",
  "words": [
    {
      "id": "uuid",
      "term": "英単語",
      "definition": "日本語の意味"
    }
  ]
}
```

生成されたJSONをアプリにコピー＆ペーストするだけで、単語帳が作成されます。

## 注意事項

1. **UUID**: すべてのIDは有効なUUID形式である必要があります
2. **文字エンコーディング**: UTF-8を使用してください
3. **スレッドセーフ**: Realm操作は自動的にスレッドセーフに処理されます
4. **重複**: 同じIDのデータをインポートすると上書きされます

## 将来の拡張

- ファイルからのインポート
- URLからのインポート
- クラウド同期
- 共有機能（エクスポートして他のユーザーと共有）
