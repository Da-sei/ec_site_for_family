# Requirements Document

## Project Description (Input)
wishlist-itemのfrontend側の実装をして

## Introduction

バックエンドに実装済みのウィッシュリスト機能（`/wishlist` APIエンドポイント群）に対応する Flutter フロントエンド実装。グループメンバーがグループ内で「欲しいアイテム」を投稿・閲覧・編集・削除できる画面群と状態管理を追加する。既存の `item`, `favorite`, `request` フィーチャーと同じ Riverpod StateNotifier パターンに準拠して実装する。

---

## Requirements

### Requirement 1: WishlistItem データモデル

**Objective:** Flutterアプリ開発者として、バックエンドの `WishlistItemDto` に対応する Dart モデルを用意したい。そうすることで、API レスポンスを型安全に扱える。

#### Acceptance Criteria
1. The Flutter App shall `core/models/models.dart` に `WishlistItem` クラスを追加する（フィールド: `id`, `title`, `description`, `groupId`, `requesterId`, `requester`（`User` 型）, `createdAt`, `updatedAt`）
2. When JSON データが渡されたとき, the Flutter App shall `WishlistItem.fromJson` ファクトリメソッドで `WishlistItem` インスタンスを生成する
3. The Flutter App shall `description` フィールドを nullable（`String?`）として定義する
4. The Flutter App shall `createdAt` / `updatedAt` を `DateTime` 型としてパースする

---

### Requirement 2: ウィッシュリスト状態管理

**Objective:** Flutterアプリ開発者として、ウィッシュリストの状態を Riverpod で管理したい。そうすることで、画面間で一貫した状態を共有し、APIとの同期を行える。

#### Acceptance Criteria
1. The Flutter App shall `features/wishlist/wishlist_state.dart` に `WishlistState` クラスを定義する（フィールド: `items`（`List<WishlistItem>`）, `isLoading`, `errorMessage`, `isSubmitting`）
2. The Flutter App shall `WishlistState.copyWith` メソッドで不変更新をサポートする
3. The Flutter App shall `features/wishlist/wishlist_provider.dart` に `WishlistNotifier extends StateNotifier<WishlistState>` を定義する
4. When `loadWishlistItems(groupId)` が呼ばれたとき, the Flutter App shall `GET /wishlist?groupId=:id` を呼び出し結果をステートに反映する
5. When `createWishlistItem(groupId, title, description)` が呼ばれたとき, the Flutter App shall `POST /wishlist` を呼び出し成功したら一覧を再取得する
6. When `updateWishlistItem(id, title, description)` が呼ばれたとき, the Flutter App shall `PATCH /wishlist/:id` を呼び出し成功したら一覧を再取得する
7. When `deleteWishlistItem(id)` が呼ばれたとき, the Flutter App shall `DELETE /wishlist/:id` を呼び出し成功したら一覧から該当アイテムを除去する
8. If API 呼び出しが失敗したとき, the Flutter App shall `errorMessage` にエラーメッセージを設定する

---

### Requirement 3: ウィッシュリスト一覧画面

**Objective:** グループメンバーとして、現在選択中のグループのウィッシュリスト一覧を確認したい。そうすることで、誰が何を欲しがっているかを把握できる。

#### Acceptance Criteria
1. The Flutter App shall `features/wishlist/wishlist_list_screen.dart` にウィッシュリスト一覧画面を実装する
2. While 画面が表示されているとき, the Flutter App shall 選択中グループの `groupId` を使って `loadWishlistItems` を呼び出す
3. The Flutter App shall 各ウィッシュリストアイテムをリスト形式で表示する（タイトル・説明（任意）・投稿者名・投稿日時）
4. While ローディング中のとき, the Flutter App shall `CircularProgressIndicator` を表示する
5. If ウィッシュリストが空のとき, the Flutter App shall 空状態のメッセージを表示する
6. The Flutter App shall `MainScaffold` を使ってボトムナビゲーションバーを含む標準レイアウトで画面を構成する
7. The Flutter App shall 投稿者が現在のログインユーザーである場合、アイテムに編集・削除の操作メニューを表示する
8. When 削除操作が選択されたとき, the Flutter App shall 確認ダイアログを表示してから `deleteWishlistItem` を呼び出す
9. When 編集操作が選択されたとき, the Flutter App shall 編集画面に遷移する
10. The Flutter App shall `FloatingActionButton`（「リクエストを投稿」）でウィッシュリスト投稿画面に遷移できるようにする

---

### Requirement 4: ウィッシュリスト投稿画面

**Objective:** グループメンバーとして、欲しいアイテムをウィッシュリストに投稿したい。そうすることで、他のメンバーに自分のニーズを伝えられる。

#### Acceptance Criteria
1. The Flutter App shall `features/wishlist/wishlist_create_screen.dart` にウィッシュリスト投稿フォーム画面を実装する
2. The Flutter App shall タイトル入力フィールド（必須、最大200文字）と説明入力フィールド（任意、複数行）を提供する
3. If タイトルが空のまま送信されたとき, the Flutter App shall フォームバリデーションエラーを表示して送信を防ぐ
4. When 送信ボタンが押されたとき, the Flutter App shall `createWishlistItem` を呼び出す
5. While 送信中のとき, the Flutter App shall 送信ボタンをローディング表示に切り替えて二重送信を防ぐ
6. When 投稿が成功したとき, the Flutter App shall 前の画面（ウィッシュリスト一覧）に戻る
7. If API エラーが発生したとき, the Flutter App shall エラーメッセージを `SnackBar` で表示する

---

### Requirement 5: ウィッシュリスト編集画面

**Objective:** 投稿者として、自分が投稿したウィッシュリストアイテムを編集したい。そうすることで、内容を正確に伝えられるよう更新できる。

#### Acceptance Criteria
1. The Flutter App shall `features/wishlist/wishlist_edit_screen.dart` に編集フォーム画面を実装する
2. The Flutter App shall 既存のタイトル・説明を初期値としてフォームにセットする
3. If タイトルが空のまま送信されたとき, the Flutter App shall フォームバリデーションエラーを表示して送信を防ぐ
4. When 送信ボタンが押されたとき, the Flutter App shall `updateWishlistItem` を呼び出す
5. While 送信中のとき, the Flutter App shall 送信ボタンをローディング表示に切り替えて二重送信を防ぐ
6. When 更新が成功したとき, the Flutter App shall 前の画面（ウィッシュリスト一覧）に戻る
7. If API エラーが発生したとき, the Flutter App shall エラーメッセージを `SnackBar` で表示する

---

### Requirement 6: ルーティングとナビゲーション統合

**Objective:** Flutterアプリ開発者として、ウィッシュリスト関連画面をアプリ内のナビゲーションに統合したい。そうすることで、ユーザーが既存の操作フローの中でウィッシュリストにアクセスできる。

#### Acceptance Criteria
1. The Flutter App shall `router.dart` にウィッシュリスト一覧画面へのルート（`/wishlist`）を追加する
2. The Flutter App shall `router.dart` にウィッシュリスト投稿画面へのルート（`/wishlist/create`）を追加する
3. The Flutter App shall `router.dart` にウィッシュリスト編集画面へのルート（`/wishlist/:id/edit`）を追加する
4. The Flutter App shall `MainScaffold` のボトムナビゲーションバーにウィッシュリストタブを追加し（例: `card_giftcard_rounded` アイコン、「ほしい物」ラベル）、`/wishlist` に遷移するようにする
5. When ウィッシュリストタブが選択されたとき, the Flutter App shall グループが未選択の場合にグループ選択を促すメッセージを表示する
6. The Flutter App shall 各ルートに `_fadeSlidePage` トランジションを適用する（既存パターンと統一）
