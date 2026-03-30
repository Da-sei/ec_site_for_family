# ギャップ分析レポート: auth-token-redirect

## 分析サマリー

- **既存実装**: Requirement 1〜3の骨格（Dioインターセプター・sessionExpiredProvider・RouterRedirect）は実装済み
- **主なギャップ**: SnackBar通知（Requirement 4）と冪等性ガード（Requirement 1-3）が未実装
- **推奨アプローチ**: Option A（AuthStateへのフラグ追加）— 既存パターンと最も整合的
- **実装規模**: S（1〜3日）、リスク: Low
- **影響範囲**: `auth_state.dart`・`auth_provider.dart`・`login_screen.dart` の3ファイルのみ

---

## 1. 現状調査

### 関連ファイル・モジュール

| ファイル | 役割 | 状態 |
|---|---|---|
| `frontend/lib/core/network/api_client.dart` | Dioインターセプター・`sessionExpiredProvider` | 稼働中 |
| `frontend/lib/core/network/auth_repository.dart` | `flutter_secure_storage` ラッパー | 稼働中 |
| `frontend/lib/features/auth/auth_provider.dart` | `AuthNotifier`・`authProvider` | 稼働中 |
| `frontend/lib/features/auth/auth_state.dart` | `AuthState`（不変クラス） | 稼働中 |
| `frontend/lib/features/auth/login_screen.dart` | ログイン画面（ConsumerStatefulWidget） | 稼働中 |
| `frontend/lib/router.dart` | GoRouter + `_RouterNotifier` | 稼働中 |

### 既存の認証フロー（現状）

```
HTTP 401 発生
  → Dioインターセプター: authRepo.clearAll() + sessionExpiredProvider++
  → authProvider.ref.listen: notifier.logout() を呼び出し
  → AuthNotifier.logout(): state = const AuthState()（isAuthenticated: false）
  → _RouterNotifier: authProviderの変化を検知 → GoRouterに通知
  → redirect(): isAuthenticated=false かつ authRouteでない → '/login'
```

### SnackBarパターン（既存の慣例）

- 全画面で `ScaffoldMessenger.of(context).showSnackBar(...)` を使用
- `main.dart`に `snackBarTheme`（floating + border-radius）定義済み
- 必ず `if (mounted)` ガードで Widget スコープ内で呼び出し
- ConsumerStatefulWidgetの `initState` + `WidgetsBinding.addPostFrameCallback` でフレーム後実行するパターンが標準的

---

## 2. 要件別ギャップ分析

### Requirement 1: トークン期限切れの検知

| 受け入れ基準 | 既存アセット | ステータス |
|---|---|---|
| R1-1: HTTP 401 でセッション終了処理を開始 | Dioインターセプター（`onError` で 401 検知） | ✅ 実装済み |
| R1-2: 全認証済みAPIリクエストを監視 | `dioProvider` のグローバルインターセプター | ✅ 実装済み |
| R1-3: 複数401の冪等性保証 | `ref.listen` が毎回 `logout()` を呼ぶため重複実行の可能性あり | ⚠️ ギャップ |

**R1-3 詳細**: `sessionExpiredProvider` は `StateProvider<int>`（カウンター）。
`ref.listen` で `next > prev` の条件はあるが、連続した複数の 401 は複数回 `logout()` を呼ぶ。
`logout()` は `clearAll()` + 状態リセットのため副作用は軽微だが、厳密な冪等性のためには `isAuthenticated` チェックが必要。

---

### Requirement 2: 認証状態のクリア

| 受け入れ基準 | 既存アセット | ステータス |
|---|---|---|
| R2-1: JWTトークン削除 | `authRepo.clearAll()` → `_storage.delete(key: 'access_token')` | ✅ 実装済み |
| R2-2: `isAuthenticated` リセット | `logout()` → `state = const AuthState()` | ✅ 実装済み |
| R2-3: アカウントIDなど全セッション状態クリア | `clearAll()` → `account_id` も削除 | ✅ 実装済み |

---

### Requirement 3: ログインページへの自動リダイレクト

| 受け入れ基準 | 既存アセット | ステータス |
|---|---|---|
| R3-1: `isAuthenticated=false` → `/login` 自動遷移 | `router.dart` の `redirect()` ロジック | ✅ 実装済み |
| R3-2: ログイン・登録画面での再リダイレクト防止 | `isAuthRoute` チェック（`/login`, `/register`） | ✅ 実装済み |
| R3-3: セッション終了中の認証ページブロック | router redirect で全非認証アクセスを `/login` へ | ✅ 実装済み |

---

### Requirement 4: ユーザーへのフィードバック通知

| 受け入れ基準 | 既存アセット | ステータス |
|---|---|---|
| R4-1: セッション切れSnackBarを表示 | なし | ❌ 未実装 |
| R4-2: ログイン画面遷移後に表示 | SnackBarテーマはmain.dartで定義済み | 🔧 基盤あり・組み込み未実装 |
| R4-3: 通常ログアウトとセッション切れを区別 | なし（`logout()`は単一メソッド） | ❌ 未実装 |

**R4 課題**: SnackBar表示には `BuildContext` が必要だが、401検知はDioインターセプター（プロバイダー外）、ログアウトは `AuthNotifier`（Widgetスコープなし）で発生する。
`LoginScreen` がマウントされる前にリダイレクトが完了するため、**画面側で「セッション切れ状態」を初期描画時に検知する仕組み**が必要。

---

## 3. 実装アプローチ比較

### Option A: `AuthState`に`isSessionExpired`フラグを追加（推奨）

**変更ファイル**:
- `auth_state.dart`: `isSessionExpired: bool` フィールド追加
- `auth_provider.dart`: `sessionExpiredLogout()` メソッド追加（冪等性ガード含む）+ `clearSessionExpired()` 追加
- `login_screen.dart`: `initState` + `addPostFrameCallback` でフラグ確認・SnackBar表示

**フロー（Option A）**:
```
401 検知 → sessionExpiredProvider++
  → authProvider.ref.listen:
      if (state.isAuthenticated) {  // 冪等性ガード
        notifier.sessionExpiredLogout()  // isSessionExpired=true + clearAll + reset
      }
  → router: isAuthenticated=false → /login へリダイレクト
  → LoginScreen.initState():
      addPostFrameCallback(() {
        if (ref.read(authProvider).isSessionExpired) {
          showSnackBar("セッションの有効期限が切れました");
          ref.read(authProvider.notifier).clearSessionExpired();
        }
      })
```

**トレードオフ**:
- ✅ 既存の Riverpod StateNotifier パターンと完全に一致
- ✅ 通常 `logout()` と `sessionExpiredLogout()` の区別が明確
- ✅ `LoginScreen` 側の変更が最小限
- ❌ `AuthState` に表示制御フラグが混入（SRP観点で微妙）

---

### Option B: 独立した `sessionExpiredMessageProvider`

**変更ファイル**:
- `api_client.dart`: `sessionExpiredMessageProvider = StateProvider<String?>` を追加
- `auth_provider.dart`: `ref.listen` でメッセージをセット、冪等性ガード追加
- `login_screen.dart`: `initState` でプロバイダー値を確認・SnackBar表示・クリア

**トレードオフ**:
- ✅ `AuthState` にUI制御ロジックが入らず関心分離が明確
- ✅ 将来的にエラーメッセージ種別の拡張が容易
- ❌ プロバイダーが1つ増えるが、`api_client.dart` には既に `sessionExpiredProvider` が存在するため自然

---

### Option C: `GlobalKey<ScaffoldMessengerState>` をグローバル公開

**変更ファイル**:
- `main.dart`: `scaffoldMessengerKey` を定義し `MaterialApp.router` に渡す
- `api_client.dart` または `auth_provider.dart`: キー経由で SnackBar 表示

**トレードオフ**:
- ✅ Widget ツリー外から直接 SnackBar を表示可能
- ❌ グローバル状態の導入はFlutterの推奨パターンから外れる
- ❌ GoRouterとの画面遷移タイミング制御が複雑

---

## 4. 実装難易度・リスク評価

| 項目 | 評価 | 根拠 |
|---|---|---|
| 実装規模 | **S（1〜3日）** | 既存パターンへの拡張3ファイル。新規アーキテクチャ不要 |
| リスク | **Low** | 既存認証フロー（R1〜3）は動作済み。R4のみ追加。既存テストに影響なし |

---

## 5. 設計フェーズへの推奨事項

**採用アプローチ**: Option A または Option B（どちらも実装コスト・リスクは同等）

**設計フェーズで決定すべき事項**:
1. `isSessionExpired` を `AuthState` に持つか（Option A）、独立プロバイダーにするか（Option B）
2. `LoginScreen` での SnackBar 表示タイミング（`initState` + `addPostFrameCallback` vs `ref.listen` + 状態変化検知）
3. 冪等性ガードの正確な実装（`isAuthenticated` チェックの位置）

**Research Needed**:
- なし（既存技術スタックのみで対応可能）
