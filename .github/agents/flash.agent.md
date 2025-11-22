# AGENTS.md
owner: @team
version: 1.0
last_updated: 2025-10-21

## Goal
推測をやめ、既存の設計と作法に従って**小さな差分**でPRを作る。

## Do
- UI: <UIライブラリ名> v<バージョン> を使用。スタイルは <推奨スタイル記法>。
- 状態管理: <採用ライブラリ>。代替の乱用は避ける。
- データ取得: **コンポーネント内に直書き禁止**。`app/api/client.ts` を経由。
- デザイン: 色/影/余白は**トークン**から取得（`app/lib/theme/tokens.ts`）。
- 実装: **小さなコンポーネント**と**小さなPR**（Diff上限: 300行）。

## Don't
- 色のハードコード、既存コンポーネント無視のdiv多用
- 承認なしの依存追加、フルビルド/E2Eの無断実行
- 設計を逸脱した独自構造

## Commands（単一ファイル）
- 型チェック: `npm run tsc --noEmit path/to/file.tsx`
- 整形: `npm run prettier --write path/to/file.tsx`
- Lint: `npm run eslint --fix path/to/file.tsx`
- テスト: `npm run vitest run path/to/file.test.tsx`
- フルビルド: `npm run build`（**要許可**）

## Safety & Permissions
Allowed:
- ファイル閲覧、上記の単一ファイル処理

Ask first:
- 依存追加・削除、`git push`
- ファイル削除・権限変更
- フルビルド、E2E/統合テスト

## Project Map
- ルーティング: `App.tsx`
- サイドバー: `AppSideBar.tsx`
- 共通コンポーネント: `app/components`
- テーマトークン: `app/lib/theme/tokens.ts`
- データクライアント: `app/api/client.ts`

## Good / Bad Examples
- ✅ 参考: `app/components/Projects.tsx`（フック構成）
- ❌ 模倣禁止: `app/pages/Admin.tsx`（レガシー）

## API
- 例: GET `/api/projects` → `client.projects.list()`
- 例: PATCH `/api/projects/:id` → `client.projects.update()`

## PR Checklist
- 型/Lint/テスト**ALL GREEN**
- Diffは小さく、要約コメントを先頭に
- ログ・不要コメントは削除

## When Stuck
- **質問**を投げる
- **短い計画**を提案（タスク分割）
- **Draft PR**を開く（推測で500行はNG）

## Test-First Mode
- 新機能・バグ修正は**テスト先行**（UIはコンポーネントテスト）

## Design System
- 既存UI: `@acme/ui` を使用
- トークン: `@acme/ui/tokens`
- 例: `./design-system-index/examples`
