# リサーチ & 設計決定ログ

---

## Summary

- **Feature**: `family-marketplace`
- **Discovery Scope**: New Feature（既存インフラ上への新規実装）
- **Key Findings**:
  - 既存 `UserModule` は定義済みだが `AppModule` にインポートされておらず、`UserCommandRepository.signIn()` のシグネチャがインターフェースと不一致。設計では修正が必要。
  - 既存 Prisma スキーマ（`Users`, `Items`, `Favorite`）は要件と乖離が大きいため全面再設計が必要。`email` 必須・`Favorite` モデルの廃止・`status`/`groupId` の追加など。
  - Flutter フロントエンドは `main.dart` のみで実質ゼロから実装。Feature-first 構成 + Riverpod を採用する。

---

## Research Log

### JWT 認証（NestJS）

- **Context**: accountId (UUID) + password 認証を JWT で実装する必要がある
- **Sources Consulted**: NestJS 公式ドキュメント（Authentication）、passport-jwt, @nestjs/jwt
- **Findings**:
  - `@nestjs/passport` + `passport-jwt` が NestJS の標準的な JWT 実装
  - `LocalStrategy`（ID/パスワード検証）→ `JwtStrategy`（トークン検証）の2段構成
  - `bcryptjs` でパスワードハッシュ化
  - Refresh Token は separate DB 管理が安全だが、家族向け小規模アプリのためアクセストークン有効期限延長（例: 7d）で簡略化可
- **Implications**: `AuthModule` を新設し、`UserModule` から認証ロジックを分離する

### 画像ストレージ

- **Context**: 商品画像のアップロード・配信が必要
- **Findings**:
  - 家族向け小規模アプリのため、クラウドストレージ（S3等）は過剰
  - NestJS `multer` ミドルウェアでローカルファイルシステムに保存 → `/uploads/items/` ディレクトリ
  - Docker Compose で `volumes` マウントすることで永続化
  - NestJS の `ServeStaticModule` または `Express.static()` で静的配信
- **Implications**: `Docker Compose` に `uploads` ボリュームを追加する

### Flutter 状態管理

- **Context**: Flutter フロントエンドの状態管理アーキテクチャ選定
- **Findings**:
  - **Riverpod 2.x** (`flutter_riverpod`): 型安全・テスタブル・ボイラープレートが少ない。2024-2026年の Flutter 標準的選択肢。
  - **Provider**: 旧世代、Riverpod が後継
  - **BLoC**: 大規模向け、家族アプリには過剰
- **Implications**: `flutter_riverpod` + `riverpod_annotation` を採用

### Flutter HTTP & ストレージ

- **Findings**:
  - `dio`: インターセプター（JWT 自動付与・401 自動リフレッシュ）が容易
  - `flutter_secure_storage`: Keychain（iOS）/ Keystore（Android）に JWT 保存
  - `image_picker`: カメラ・ギャラリーアクセス（iOS: Info.plist 権限設定が必要）
  - `share_plus`: OS シェアシート呼び出し（Flutter 公式推奨）
  - `go_router`: 宣言的ルーティング、認証状態に応じたリダイレクト容易

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| DDD + CQRS（既存踏襲） | ドメインごとにモジュール分割、Command/Queryリポジトリ分離 | 既存パターンに一貫性、テスタブル | 小規模アプリでは冗長な場合も | 既存 steering と完全一致 |
| シンプルな MVC | Controller → Service → Repository の1層 | 実装速度が高い | スケール時に混乱しやすい | 却下 |
| Event-driven / CQRS + Event Sourcing | イベント駆動での状態管理 | スケーラブル | 過剰複雑性 | 却下 |

---

## Design Decisions

### Decision: メール不要の accountId 認証

- **Context**: 要件1.1〜1.4 で accountId（UUID）+ password のみで認証
- **Alternatives Considered**:
  1. メールアドレス維持（既存スキーマ踏襲）
  2. メールなし・accountId のみ（採用）
- **Selected Approach**: `Users` テーブルから `email` を削除し、`accountId`（UUID, システム自動生成）+ `passwordHash` で認証
- **Rationale**: 家族間アプリでメールアドレスは不要、プライバシー観点からも最小限の個人情報
- **Trade-offs**: メールによるパスワードリセット不可（家族間なので許容）

### Decision: 画像ローカルストレージ

- **Context**: 商品画像の永続化
- **Selected Approach**: Docker volume マウント + multer によるローカル保存 + 静的配信
- **Rationale**: S3 等は費用・設定の複雑さがあり、家族向け小規模アプリには不要
- **Trade-offs**: スケール不可、サーバー移行時にデータ移行が必要

### Decision: プッシュ通知は MVP スコープ外

- **Context**: 要件4.1 で申し込み時の通知が必要
- **Selected Approach**: 初期 MVP ではプッシュ通知なし。申し込み一覧をポーリングまたは手動リフレッシュで対応
- **Rationale**: FCM 連携は Firebase 設定・証明書管理が必要で実装コストが高い
- **Trade-offs**: UX はやや劣るが、家族間用途では許容範囲

### Decision: Prisma スキーマ全面再設計

- **Context**: 既存スキーマ（`email` 必須, `Favorite` モデル, 価格あり）が要件と乖離
- **Selected Approach**: 既存スキーマを廃棄し、新規スキーマを定義。`Users`/`Items` のカラム変更、`Groups`/`Requests` 等の追加
- **Rationale**: 既存モデルの互換性維持より設計の整合性を優先（初期開発段階のため）

---

## Risks & Mitigations

- **画像アップロードサイズ超過** — multer の `limits.fileSize` を設定（例: 5MB）し、クライアント側でも事前リサイズ
- **accountId 重複** — UUID v4 の衝突確率は実質ゼロだが、DB に `@unique` 制約を設ける
- **トークン有効期限切れ** — アクセストークン7日間で Refresh Token なし設計（家族アプリ）; 将来的に Refresh Token 追加可能
- **グループスコープ漏洩** — 全 API エンドポイントで `GroupMemberGuard` を適用し、グループ外アクセスを防止
- **競合（同時申し込み）** — `Requests` テーブルの `status` 更新は DB トランザクションで保護、"AVAILABLE でない商品への申し込み" を 409 で拒否

---

## References

- NestJS Authentication: https://docs.nestjs.com/security/authentication
- Prisma Schema Reference: https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference
- Flutter Riverpod: https://riverpod.dev
- share_plus: https://pub.dev/packages/share_plus
- flutter_secure_storage: https://pub.dev/packages/flutter_secure_storage
