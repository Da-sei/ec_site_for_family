# Research & Design Decisions

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

---

## Summary
- **Feature**: `wishlist-frontend`
- **Discovery Scope**: Extension（既存 Flutter フロントエンドへの機能追加）
- **Key Findings**:
  - 既存フィーチャーはすべて `StateNotifier + StateNotifierProvider` パターンに統一されており、`WishlistNotifier` も同パターンで実装できる
  - `AuthState` は `userId`（数値）を保持せず `accountId`（文字列）のみ。WishlistItemDto の `requester.accountId` と比較することで所有者判定が可能
  - `MainScaffold` のボトムナビゲーションバーは現在4タブ固定。5タブ追加には `main_scaffold.dart` の変更が必要

---

## Research Log

### 既存フロントエンドアーキテクチャ調査

- **Context**: wishlist フィーチャーで準拠すべきパターンを確認
- **Findings**:
  - 全フィーチャーが `{feature}_state.dart` / `{feature}_provider.dart` / `{feature}_screen.dart` の3ファイル構成
  - `StateNotifier<XxxState>` + `StateNotifierProvider` が状態管理の唯一のパターン
  - `Dio`（`dioProvider`）で全API呼び出し。JWT は interceptor で自動付与
  - `go_router`（`routerProvider`）で全ルーティング管理。遷移は `_fadeSlidePage` ヘルパーを統一適用
  - `MainScaffold` が AppBar + BottomNavBar + body の共通レイアウトを提供
- **Implications**: wishlist も同パターンで実装。独自の DI や状態管理は不要

### 所有者判定（Owner Detection）の方法

- **Context**: 一覧画面で自分の投稿かどうか判定し、編集・削除メニューを出す必要がある
- **Findings**:
  - `AuthState.userId`（int）は存在しない。`AuthState.accountId`（String）のみ
  - バックエンド `GET /wishlist?groupId=:id` レスポンスには `requester: { id, accountId, name }` が含まれる
  - `requester.accountId == authState.accountId` で比較可能（どちらも文字列）
- **Implications**: `WishlistListScreen` で `ref.watch(authProvider).accountId` を取得し、`item.requester.accountId` と比較する。別API呼び出し不要

### BottomNavigationBar への統合

- **Context**: ウィッシュリスト画面へのナビゲーション手段の設計
- **Findings**:
  - 現在のボトムナビは `main_scaffold.dart` に `case 0〜3` としてハードコード
  - `selectedIndex` パラメータで現在のタブを指定する設計
  - `BottomNavigationBarType.fixed` を使用しており、5タブ追加が可能
- **Implications**: `main_scaffold.dart` に `case 4` を追加し `/wishlist` 遷移を追加。各画面の `selectedIndex` 指定も更新

### グループ選択との連携

- **Context**: ウィッシュリストはグループスコープ。`groupProvider.selectedGroupId` を参照する方針
- **Findings**:
  - `ItemListNotifier.setGroupId(int)` が `groupProvider.selectedGroupId` の変更を `ref.listen` で受け取るパターンを使用
  - `WishlistNotifier` も同様に `groupId` をフィールドとして保持し、`setGroupId` メソッドで切り替え時に再取得する
- **Implications**: `WishlistListScreen` の `initState` で `groupProvider` をロードし、`ref.listen` でグループ変更を検知して再取得

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| StateNotifier パターン（採用） | 既存フィーチャーと同一パターン | コードの一貫性、既存テストパターン流用可能 | なし | 全フィーチャーで統一済み |
| ChangeNotifier | Flutter 標準 | 学習コスト低 | Riverpod との相性不良 | 既存コードで未使用 |
| Cubit / BLoC | 明示的なイベント駆動 | 大規模向き | このプロジェクトには過剰設計 | 既存コードで未使用 |

---

## Design Decisions

### Decision: 所有者判定に accountId 比較を使用する

- **Context**: 一覧画面でログインユーザーが投稿者かどうかを判定する必要がある
- **Alternatives Considered**:
  1. `authState.accountId == item.requester.accountId` — 文字列比較（追加APIなし）
  2. `/auth/me` などのAPIを呼んでユーザーIDを取得 — 追加呼び出しが必要
- **Selected Approach**: `authState.accountId == item.requester.accountId` で比較
- **Rationale**: `AuthState` に文字列の `accountId` が既にあり、`WishlistItemDto.requester.accountId` も含まれる。追加API呼び出し不要
- **Trade-offs**: accountId の変更可能性は現時点で設計外のため問題なし

### Decision: WishlistNotifier に groupId を内部保持させる

- **Context**: `ItemListNotifier` と同様に、グループ選択変更時に一覧を再取得する必要がある
- **Alternatives Considered**:
  1. `groupId` をメソッド引数で毎回渡す
  2. `groupId` をプロバイダの外部状態として保持 — `setGroupId()` パターン（`ItemListNotifier` と同じ）
- **Selected Approach**: `WishlistNotifier` に `int? _groupId` フィールドを持たせ、`setGroupId(int)` で切り替え
- **Rationale**: `ItemListNotifier` と完全に対称的なパターンで実装できる。一貫性が高い
- **Trade-offs**: なし

---

## Risks & Mitigations

- `MainScaffold` の `selectedIndex` が 0〜3 を前提としている画面が複数存在 → `wishlist` 画面を `selectedIndex: 4` で追加し、既存画面の値を変更しないことで影響を最小化
- `authState.accountId` が null の場合（初期化中）は所有者判定で false とする → null 安全な比較で対応

---

## References

- バックエンド設計: `.kiro/specs/item-wishlist/design.md`（API コントラクト定義）
- 既存フィーチャーパターン: `frontend/lib/features/favorite/`, `frontend/lib/features/item/`
