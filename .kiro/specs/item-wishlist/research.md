# Research & Design Decisions

---
**Feature**: `item-wishlist`
**Discovery Scope**: Extension（既存NestJS DDDコードベースへの新ドメイン追加）
**Key Findings**:
- `favorite` ドメインが最も近い構造の参照実装（単一リポジトリ、GroupMemberGuard利用）
- `GroupMemberGuard` はクエリパラメータ `groupId` またはアイテムID経由（`items`テーブル）のみ対応しており、wishlistの詳細参照には流用不可
- 投稿者確認（owner check）は `ItemOwnerGuard` と同等の `WishlistItemOwnerGuard` を新規作成することで対応可能

---

## Research Log

### GroupMemberGuard の流用可否分析

- **Context**: ウィッシュリストへのアクセスをグループメンバーに限定するための認可ガードの設計
- **Sources Consulted**: `backend/src/common/guards/group-member.guard.ts`
- **Findings**:
  - クエリパラメータ `groupId` がある場合はそのまま使用できる → `GET /wishlist?groupId=:id` で流用可能
  - ルートパラメータ `:id` がある場合は `items` テーブルを参照しているため、wishlistルートには流用不可
  - リクエストボディの `groupId` には対応していない
- **Implications**:
  - `POST /wishlist`：サービス層でメンバーシップ検証
  - `GET /wishlist?groupId=:id`：`GroupMemberGuard` 流用
  - `GET /wishlist/:id`：サービス層でメンバーシップ検証
  - `PATCH /wishlist/:id` / `DELETE /wishlist/:id`：新規 `WishlistItemOwnerGuard` で対応（オーナーはグループメンバーが前提）

### 既存ドメインのリポジトリ分割パターン分析

- **Context**: 新ドメインでCQRS分割（Command/Queryリポジトリ）が必要か判断
- **Sources Consulted**: `backend/src/domains/favorite/`, `backend/src/domains/user/`
- **Findings**:
  - `user` ドメインのみCQRS分割を採用（`UserCommandRepository` / `UserQueryRepository`）
  - `favorite`, `group`, `item`, `request` はすべて単一 `IXxxRepository` を採用
  - wishlistは書き込み・読み込みの分離が必要なほど複雑ではない
- **Implications**: 単一 `IWishlistRepository` を採用する

### Prisma スキーマ拡張設計

- **Context**: `WishlistItems` テーブルの設計
- **Sources Consulted**: `backend/prisma/schema.prisma`
- **Findings**:
  - `Items` モデルに倣い `title(String)`, `description(String?)`, `requesterId(Int FK)`, `groupId(Int FK)` を基本フィールドとする
  - `createdAt` / `updatedAt` は全モデルの標準パターン
  - `Users` と `Groups` に逆参照リレーションを追加する必要がある
- **Implications**: Prismaマイグレーション1件追加。既存テーブルへの破壊的変更なし

---

## Architecture Pattern Evaluation

| Option | 説明 | 強み | リスク／制限 | 判断 |
|--------|------|------|------------|------|
| 単一リポジトリ | `IWishlistRepository` 1つ | シンプル・既存パターンに準拠 | 将来的な読み書き分離が必要になった場合に再構成要 | **採用** |
| CQRS分割 | Command/Queryリポジトリ分離 | スケーラブル | オーバーエンジニアリング | 不採用 |
| サービス内直Prisma呼び出し | リポジトリ層なし | 実装が速い | テスト困難・アーキテクチャ逸脱 | 不採用 |

---

## Design Decisions

### Decision: 投稿者確認（owner check）の方式

- **Context**: PATCH / DELETE はウィッシュリスト投稿者のみ許可する必要がある
- **Alternatives Considered**:
  1. サービス層で `requesterId === userId` を確認
  2. `WishlistItemOwnerGuard`（`ItemOwnerGuard` と同等）を新設
- **Selected Approach**: `WishlistItemOwnerGuard` を `common/guards/` に新設
- **Rationale**: `ItemOwnerGuard` と同じパターンを踏襲することでアーキテクチャの一貫性を保つ。コントローラー層で宣言的に認可を表現できる
- **Trade-offs**: ガードが増えるがWishlistItemsテーブルへの参照は軽量（PK検索1回）

### Decision: グループメンバーシップ検証の方式

- **Context**: POST（作成）と GET /:id（詳細）はサービス層でグループメンバーシップを確認する
- **Alternatives Considered**:
  1. `GroupMemberGuard` を拡張してWishlistItemsも参照するよう変更
  2. サービス層でPrismaを使いメンバーシップ確認
- **Selected Approach**: サービス層でメンバーシップ確認（オプション2）
- **Rationale**: `GroupMemberGuard` はitemsテーブルへの依存を持っており、wishlist対応の変更はSRP違反になる。サービス層での確認は既存コードへの影響ゼロ
- **Trade-offs**: 認可ロジックがガードとサービスに分散するが、ドメイン分離の観点では適切

---

## Risks & Mitigations

- `WishlistItemOwnerGuard` でwishlistが存在しない場合のNot Found処理 — ガード内で `NotFoundException` を返す
- `GroupMemberGuard` の `groupId` クエリパラメータ必須化 — `GET /wishlist?groupId=:id` のAPIドキュメントで必須明記
- Prismaマイグレーション — 既存テーブルへの変更なし・後方互換性リスクなし
