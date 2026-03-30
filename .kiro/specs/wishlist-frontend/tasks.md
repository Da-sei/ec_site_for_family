# Implementation Plan

- [x] 1. WishlistItem データモデルを追加する
- [x] 1.1 WishlistItem クラスを既存モデルファイルに追加する
  - `id`, `title`, `description`（nullable）, `groupId`, `requesterId`, `requester`（既存 User 型）, `createdAt`, `updatedAt` の各フィールドを定義する
  - `fromJson` ファクトリメソッドを実装し、バックエンドのレスポンス JSON から型安全にインスタンスを生成できるようにする
  - `createdAt` / `updatedAt` は ISO 8601 文字列から `DateTime` にパースする
  - `requester` フィールドは既存の `User.fromJson` を再利用する
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. ウィッシュリスト状態管理を実装する
- [x] 2.1 不変状態クラスを実装する
  - `items`（WishlistItem リスト）, `isLoading`, `errorMessage`, `isSubmitting` の各フィールドを持つ不変クラスを定義する
  - `copyWith` メソッドで `clearError` フラグをサポートする（既存の FavoriteState / ItemListState パターンと同一）
  - _Requirements: 2.1, 2.2_

- [x] 2.2 ウィッシュリスト操作の StateNotifier を実装する
  - `setGroupId(int)` でグループ切り替え時に自動再取得を行う（`ItemListNotifier.setGroupId` と同一パターン）
  - `loadWishlistItems` で `GET /wishlist?groupId=:id` を呼び出し、結果を `WishlistItem` リストとしてステートに反映する
  - `createWishlistItem` で `POST /wishlist` を呼び出し、成功後に一覧を再取得する。成功時 `true`、失敗時 `errorMessage` をセットして `false` を返す
  - `updateWishlistItem` で `PATCH /wishlist/:id` を呼び出し、成功後に一覧を再取得する。同上の戻り値規約
  - `deleteWishlistItem` で `DELETE /wishlist/:id` を呼び出し、成功後にステートから該当アイテムを除去する。同上の戻り値規約
  - `groupId` が null の場合は API 呼び出しをスキップする
  - API エラー時は `DioException.response?.data?['message']` をフォールバックメッセージで `errorMessage` にセットする
  - `StateNotifierProvider` として公開し、`dioProvider` を注入する
  - _Requirements: 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [x] 3. ウィッシュリスト一覧画面を実装する
  - `ConsumerStatefulWidget` として実装し、`initState` でグループをロードして初回取得を行う
  - `ref.listen` で `groupProvider.selectedGroupId` の変更を検知し `setGroupId` を呼び出す（`ItemListScreen` と同一パターン）
  - `isLoading` 中は `CircularProgressIndicator` を中央に表示する
  - アイテムがない場合は空状態のアイコンとメッセージ（「ウィッシュリストはまだありません」）を表示する
  - グループが未選択の場合は「グループを選択してください」のメッセージを表示する
  - 各アイテムをリスト形式で表示し、タイトル・説明（存在する場合）・投稿者名・投稿日時を含める
  - `authProvider.accountId == item.requester.accountId` の比較で自分の投稿を判定し、編集・削除の操作メニューを表示する
  - 削除選択時は確認ダイアログを表示し、承認後に `deleteWishlistItem` を呼び出す
  - `FloatingActionButton`（「リクエストを投稿」）で投稿画面に遷移する
  - `selectedIndex: 4` で `MainScaffold` を使用する
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10_

- [x] 4. (P) ウィッシュリスト投稿画面を実装する
  - タスク 3 と共通の `WishlistNotifier`（タスク 2 で完成）に依存するが、別ファイルで実装するため並行可能
  - `ConsumerStatefulWidget` として実装し、タイトル（必須・最大 200 文字）と説明（任意・複数行）の入力フィールドを持つフォームを定義する
  - `GlobalKey<FormState>` によるバリデーションで、タイトルが空の場合は送信を防ぎフォームエラーメッセージを表示する
  - `groupProvider.selectedGroupId` が null の場合は `SnackBar` でエラーを表示して送信を中断する
  - 送信ボタン押下時に `isSubmitting` フラグで二重送信を防ぐ
  - `createWishlistItem` 成功後は `context.pop()` で一覧画面に戻る
  - API エラー時は `SnackBar`（赤背景）でエラーメッセージを表示する
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 5. (P) ウィッシュリスト編集画面を実装する
  - タスク 3, 4 と共通の `WishlistNotifier`（タスク 2 で完成）に依存するが、別ファイルで実装するため並行可能
  - コンストラクタで `WishlistItem` を受け取り、`initState` で既存のタイトル・説明をフォームコントローラーにセットする
  - 投稿画面（タスク 4）と同一のバリデーション・二重送信防止ロジックを適用する
  - `updateWishlistItem` 成功後は `context.pop()` で一覧画面に戻る
  - API エラー時は `SnackBar`（赤背景）でエラーメッセージを表示する
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 6. ルーティングとナビゲーションを統合する
- [x] 6.1 ルーターに 3 ルートを追加する
  - タスク 3, 4, 5 の全画面完成後に実施する
  - `/wishlist` → ウィッシュリスト一覧画面、`/wishlist/create` → 投稿画面、`/wishlist/:id/edit` → 編集画面（`state.extra as WishlistItem` でアイテムを渡す）の 3 ルートを追加する
  - 全ルートに既存の `_fadeSlidePage` トランジションを適用する
  - _Requirements: 6.1, 6.2, 6.3, 6.6_

- [x] 6.2 BottomNavigationBar にウィッシュリストタブを追加する
  - `MainScaffold` の `BottomNavigationBar` に5番目のタブ（`card_giftcard_rounded` アイコン、「ほしい物」ラベル）を追加する
  - `onTap` の `case 4` で `/wishlist` に遷移するよう追加する
  - 既存タブ（`case 0〜3`）のインデックスは変更しない
  - _Requirements: 6.4, 6.5_

- [x] 7. ウィッシュリスト機能のテストを実装する
- [x] 7.1 状態管理のユニットテストを実装する
  - `WishlistItem.fromJson` の正常系および `description=null` のケースをテストする
  - `WishlistNotifier.loadWishlistItems` で API 成功時にステートが更新されること、`groupId` が null のとき呼び出しをスキップすることを検証する
  - `WishlistNotifier.createWishlistItem` で成功時に `true` が返ること、失敗時に `errorMessage` がセットされ `false` が返ることを検証する
  - `WishlistNotifier.deleteWishlistItem` で成功後に `items` から該当アイテムが除去されることを検証する
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8_

- [ ]* 7.2 画面のウィジェットテストを実装する（オプション）
  - `WishlistListScreen`: ローディング中の `CircularProgressIndicator` 表示、空状態表示、自分の投稿に編集/削除メニューが出ること、他人の投稿にメニューが出ないことを検証する
  - `WishlistCreateScreen`: タイトル空でバリデーションエラーが表示されること、送信中にボタンが無効化されることを検証する
  - `WishlistEditScreen`: 既存のタイトル・説明が初期値としてセットされることを検証する
  - _Requirements: 3.4, 3.5, 3.7, 4.3, 4.5, 5.2, 5.5_
