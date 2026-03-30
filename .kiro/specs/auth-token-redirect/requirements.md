# Requirements Document

## Project Description (Input)
トークンが期限綺麗なった場合、自動でログインページにリダイレクトされる

## Introduction

本機能は、JWTアクセストークンの期限切れを検知し、ユーザーを自動的にログインページへリダイレクトする認証フロー制御を定義する。

Flutterフロントエンドでは、APIリクエスト時にバックエンドから返される HTTP 401 レスポンスをトークン期限切れのシグナルとして扱う。検知後は認証状態をクリアし、ルーターが自動的にログイン画面へ誘導する。また、ユーザーへのフィードバック（通知メッセージ）を提供することで、なぜ画面遷移が発生したかを明示する。

---

## Requirements

### Requirement 1: トークン期限切れの検知

**Objective:** アプリユーザーとして、トークン期限切れを明示的に操作せずとも自動検知してほしい。そうすることで、期限切れ状態のまま操作を続けることなく、安全にセッションを終了できる。

#### Acceptance Criteria

1. When APIリクエストに対してサーバーが HTTP 401 レスポンスを返す, the Flutter App shall トークン期限切れとみなしてセッション終了処理を開始する
2. The Flutter App shall すべての認証済みAPIリクエストに対して、HTTP 401 レスポンスの監視を常時行う
3. If 同一セッション中に複数の HTTP 401 レスポンスが連続して発生する, the Flutter App shall セッション終了処理を重複して実行しない（冪等性を保つ）

---

### Requirement 2: 認証状態のクリア

**Objective:** アプリユーザーとして、期限切れトークンが端末に残存しないようにしてほしい。そうすることで、無効なトークンが次回以降のリクエストに使用されるリスクをなくせる。

#### Acceptance Criteria

1. When トークン期限切れが検知される, the Flutter App shall `flutter_secure_storage` に保存されているJWTトークンを削除する
2. When トークン期限切れが検知される, the Flutter App shall 認証プロバイダーの `isAuthenticated` 状態を `false` にリセットする
3. When トークン期限切れが検知される, the Flutter App shall アカウントIDなどのセッション関連状態をクリアする

---

### Requirement 3: ログインページへの自動リダイレクト

**Objective:** アプリユーザーとして、セッション切れの際に手動でログイン画面に戻る必要なく、自動的に誘導されてほしい。そうすることで、スムーズに再認証できる。

#### Acceptance Criteria

1. When 認証状態が `false` にリセットされる, the Flutter App shall ログイン画面（`/login`）へ自動的に遷移する
2. If ユーザーがすでにログイン画面または登録画面にいる, the Flutter App shall 再リダイレクトを発生させない（ループを防ぐ）
3. While セッション終了処理が進行中である, the Flutter App shall 認証が必要なページへのアクセスをブロックする

---

### Requirement 4: ユーザーへのフィードバック通知

**Objective:** アプリユーザーとして、なぜログイン画面に遷移したのかを知りたい。そうすることで、不意の画面遷移に戸惑うことなく、再ログインの必要性を理解できる。

#### Acceptance Criteria

1. When トークン期限切れによってログイン画面へリダイレクトされる, the Flutter App shall セッションの期限切れを通知するメッセージ（例: 「セッションの有効期限が切れました。再度ログインしてください」）をSnackBarで表示する
2. The Flutter App shall 通知メッセージをログイン画面遷移後に表示する（遷移アニメーション完了後）
3. If ユーザーが自発的にログアウトした場合, the Flutter App shall セッション期限切れの通知メッセージを表示しない（通常ログアウトとセッション切れを区別する）
