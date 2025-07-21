# Flash Cards

SwiftUIで作成したフラッシュカードアプリです。単語帳を作成して学習することができます。

## 機能

- デッキの作成・編集・削除
- フラッシュカードの追加・編集
- カードをタップして表裏を切り替え
- ローカルデータベースでの永続化

## 技術構成

- **言語**: Swift
- **フレームワーク**: SwiftUI
- **アーキテクチャ**: The Composable Architecture (TCA)
- **データベース**: Realm
- **対応OS**: iOS 15.0以降

## セットアップ

1. リポジトリをクローン
```bash
git clone https://github.com/Twada9/flash_cards.git
```

2. Xcodeでプロジェクトを開く
```bash
open flash_cards/flash_cards.xcodeproj
```

3. ビルドして実行

## 使い方

1. **デッキ作成**: ホーム画面で「+」ボタンをタップしてデッキを作成
2. **単語追加**: デッキを選択して単語と意味を追加
3. **学習**: カードをタップして表裏を切り替えながら学習

## 主要コンポーネント

- `DeckListView`: デッキ一覧画面
- `DeckDetailView`: デッキ詳細・単語一覧画面
- `FlashCardView`: フラッシュカード表示画面
- `EditWordView`: 単語編集画面

## 最近の更新

- タップ領域の改善
- 重複単語の削除機能追加
- EditWordViewの状態管理改善

## 開発者

[@Twada9](https://github.com/Twada9)
