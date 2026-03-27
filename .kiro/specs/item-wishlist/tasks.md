# Implementation Plan

## item-wishlist

---

- [x] 1. WishlistItemsテーブルをDBに追加する
  - Prismaスキーマに `WishlistItems` モデルを追加する（`title`, `description?`, `requesterId`, `groupId`, `createdAt`, `updatedAt` フィールド）
  - `Users` モデルと `Groups` モデルに逆参照リレーションを追加する
  - `prisma migrate dev` でマイグレーションファイルを生成・適用する
  - Prisma Clientを再生成してビルドエラーがないことを確認する
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 3.1_

---

- [x] 2. ウィッシュリストのドメイン層とリポジトリを実装する

- [x] 2.1 (P) リポジトリインターフェースとドメインデータ型を定義する
  - ウィッシュリストアイテムの生データ型（`WishlistItemRaw`）を定義する（id, title, description, groupId, requesterId, requester情報, 日時）
  - リポジトリの契約インターフェース（`IWishlistRepository`）を定義する（create, findByGroupId, findById, update, delete の5メソッド）
  - _Requirements: 1.1, 2.1, 2.2, 3.1, 4.1, 5.1_

- [x] 2.2 Prismaを使ってウィッシュリストリポジトリを実装する
  - `IWishlistRepository` インターフェースを実装するリポジトリクラスを作成する
  - `findByGroupId` は `requester` をincludeし、新着順（`createdAt: 'desc'`）で返す
  - `findById` は `requester` をincludeし、存在しない場合 `null` を返す
  - `create`, `update`, `delete` はそれぞれPrismaの `create`, `update`, `delete` に委譲する
  - `'WISHLIST_REPOSITORY'` DIトークンでNestJSに登録できる形にする
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 3.1_

---

- [x] 3. (P) ウィッシュリスト投稿者確認ガードを実装する
  - `common/guards/` に `WishlistItemOwnerGuard` を `ItemOwnerGuard` と対称的なパターンで作成する
  - ルートパラメータ `:id` からウィッシュリストアイテムをPrisma経由でPK検索する
  - アイテムが存在しない場合は `NotFoundException` を返す
  - `requesterId` とJWTの `user.sub` が一致しない場合は `ForbiddenException` を返す
  - `PrismaService` をDIで受け取り、タスク1のマイグレーション適用後に動作可能
  - _Requirements: 4.2, 5.2, 5.3_

---

- [x] 4. ウィッシュリストサービス層を実装する

- [x] 4.1 ウィッシュリスト作成とグループメンバーシップ確認を実装する
  - `createWishlistItem(userId, dto)` メソッドを実装する
  - `GroupMembers` テーブルを参照してリクエストユーザーが指定グループのメンバーか確認する
  - メンバーでない場合は `ForbiddenException` をスローする
  - 検証通過後、リポジトリの `create` を呼び出し、結果をDTOに変換して返す
  - 作成時に `requesterId`（`userId`）を記録することを保証する
  - _Requirements: 1.1, 1.3, 1.6_

- [x] 4.2 ウィッシュリスト一覧・詳細取得を実装する
  - `getWishlistItems(groupId)` メソッドをリポジトリの `findByGroupId` に委譲して実装する
  - `getWishlistItemById(id, userId)` メソッドを実装する
  - 詳細取得でアイテムが存在しない場合は `NotFoundException` をスローする
  - 詳細取得でリクエストユーザーがアイテムのグループのメンバーか確認し、非メンバーは `ForbiddenException`
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 3.3_

- [x] 4.3 ウィッシュリスト更新・削除を実装する
  - `updateWishlistItem(id, dto)` メソッドをリポジトリの `update` に委譲して実装し、更新後のDTOを返す
  - `deleteWishlistItem(id)` メソッドをリポジトリの `delete` に委譲して実装する
  - いずれもガード（タスク3）が先行して所有者確認済みの前提で、サービス側に重複確認は不要
  - _Requirements: 4.1, 5.1_

---

- [x] 5. コントローラー・DTOとモジュール統合を実装する

- [x] 5.1 リクエスト・レスポンスDTOとコントローラーエンドポイントを実装する
  - `CreateWishlistItemDto`（`title` 必須・最大200字, `description?`, `groupId` 必須）をclass-validatorで定義する
  - `UpdateWishlistItemDto`（`title?`, `description?`）をclass-validatorで定義する
  - 全5エンドポイント（POST, GET一覧, GET詳細, PATCH, DELETE）をコントローラーに実装する
  - `GET /wishlist?groupId=:id` に `@UseGuards(GroupMemberGuard)` を適用する
  - `PATCH /wishlist/:id` と `DELETE /wishlist/:id` に `@UseGuards(WishlistItemOwnerGuard)` を適用する
  - `@CurrentUser()` デコレータでJWT情報を取得し、サービスの各メソッドに渡す
  - _Requirements: 1.2, 1.5, 2.4, 4.3_

- [x] 5.2 WishlistModuleを作成してAppModuleに登録する
  - `WishlistModule` を作成し、`WishlistController`, `WishlistService`, `WISHLIST_REPOSITORY` トークンのDI設定を記述する
  - `PrismaModule` と `WishlistItemOwnerGuard` に必要な依存をインポートする
  - `AppModule` の `imports` に `WishlistModule` を追加する
  - アプリを起動してDIエラーがないことを確認する
  - _Requirements: 1.1, 1.5, 2.1, 3.1, 4.1, 5.1_

---

- [x]* 6.1 サービスとガードのユニットテストを実装する
  - `WishlistService.createWishlistItem`：非グループメンバーで `ForbiddenException` が投げられることを確認する
  - `WishlistService.getWishlistItemById`：非メンバーで `ForbiddenException`、存在しないIDで `NotFoundException` を確認する
  - `WishlistItemOwnerGuard`：非所有者で `ForbiddenException`、存在しないIDで `NotFoundException` を確認する
  - リポジトリはモックを使用し、サービスとガードのロジックのみを検証する
  - _Requirements: 1.6, 3.2, 3.3, 4.2, 5.2, 5.3_

- [ ]* 6.2 APIエンドポイントの統合テストを実装する
  - `POST /wishlist`：正常系201・タイトル空で400・非グループメンバーで403を検証する
  - `GET /wishlist?groupId=:id`：正常系200・`groupId` なしで403を検証する
  - `GET /wishlist/:id`：正常系200・存在しないIDで404・非メンバーで403を検証する
  - `PATCH /wishlist/:id`：所有者は200・非所有者は403・存在しないIDは404を検証する
  - `DELETE /wishlist/:id`：所有者は204・非所有者は403を検証する
  - _Requirements: 1.1, 1.2, 2.1, 2.4, 3.1, 3.2, 4.1, 5.1_
