# 実装タスク: auth-token-redirect

## Task Format

- `[ ]` = 未着手
- `[x]` = 完了
- `(P)` = 並行実行可能
- `*` = 任意（後回し可）

---

- [x] 1. AuthState にセッション切れフラグを追加する
  - `isSessionExpired: bool` フィールドをデフォルト値 `false` で追加する
  - `copyWith()` に `isSessionExpired` パラメータを追加し、省略時は既存値を維持する
  - 通常の `logout()` 呼び出し後は `isSessionExpired` が `false` のままとなることを確認する（通常ログアウトとセッション切れの区別は `AuthNotifier` 側で担保する）
  - _Requirements: 4.3_

- [x] 2. AuthNotifier にセッション切れロジックを実装する

- [x] 2.1 sessionExpiredLogout メソッドを実装する
  - `isSessionExpired: true` かつ `isAuthenticated: false` となる状態遷移を `sessionExpiredLogout()` メソッドとして実装する
  - メソッド内で `AuthRepository.clearAll()` を呼び出し、ストレージ上のトークンとアカウントIDを削除する
  - 既存の `logout()` メソッドは変更しない（`isSessionExpired` を `true` にしない通常ログアウトとの区別を保つ）
  - _Requirements: 2.2, 4.3_

- [x] 2.2 clearSessionExpired メソッドを実装する
  - `isSessionExpired` フラグを `false` にリセットする `clearSessionExpired()` メソッドを追加する
  - このメソッドは `LoginScreen` が SnackBar 表示後に呼び出す専用メソッドとして設計する
  - _Requirements: 4.3_

- [x] 2.3 authProvider の ref.listen に冪等性ガードを追加する
  - `sessionExpiredProvider` の変化を受けたとき、現在の状態が `isAuthenticated == true` の場合のみ `sessionExpiredLogout()` を呼び出すガードを追加する
  - 既存の `logout()` 呼び出しを `sessionExpiredLogout()` 呼び出しに置き換える
  - 複数の HTTP 401 が連続して発生した場合でもセッション終了処理が1回のみ実行されることを確認する
  - _Requirements: 1.1, 1.3_

- [x] 3. LoginScreen にセッション切れ SnackBar 通知を実装する
  - `ConsumerStatefulWidget` の `initState` に `WidgetsBinding.addPostFrameCallback` を追加する
  - フレーム描画完了後に `authProvider` の `isSessionExpired` フラグを確認し、`true` の場合に SnackBar を表示する
  - SnackBar のメッセージは「セッションの有効期限が切れました。再度ログインしてください」、背景色はオレンジ（`Colors.orange`）とし、通常のログイン失敗通知（赤色）と視覚的に区別する
  - SnackBar 表示後に `authProvider.notifier.clearSessionExpired()` を呼び出してフラグをリセットする
  - `addPostFrameCallback` 内で `if (!mounted) return` ガードを設け、Widget がアンマウントされている場合は処理をスキップする
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 4. テスト

- [x] 4.1 (P) AuthState と AuthNotifier のユニットテストを作成する
  - `sessionExpiredLogout()` 呼び出し後に `isSessionExpired: true, isAuthenticated: false` となることを検証する
  - `clearSessionExpired()` 呼び出し後に `isSessionExpired: false` となることを検証する
  - `logout()` 呼び出し後に `isSessionExpired: false` のままであることを検証する（通常ログアウトとの区別）
  - `isAuthenticated: false` の状態で `sessionExpiredProvider` がインクリメントされても `sessionExpiredLogout()` が呼ばれないことを検証する（冪等性ガード）
  - _Requirements: 1.1, 1.3, 2.1, 2.2, 2.3, 4.3_

- [ ]* 4.2 (P) LoginScreen のウィジェットテストを作成する
  - `isSessionExpired: true` の状態で `LoginScreen` を表示したとき SnackBar が表示されることを検証する
  - `isSessionExpired: false` の状態で `LoginScreen` を表示したとき SnackBar が表示されないことを検証する
  - SnackBar 表示後に `isSessionExpired` が `false` にリセットされることを検証する
  - 通常ログアウト後に `LoginScreen` を表示しても SnackBar が表示されないことを検証する
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3_
