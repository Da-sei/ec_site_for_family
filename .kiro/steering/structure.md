---
inclusion: always
---

# プロジェクト構造

## 組織方針

**ドメイン駆動設計（DDD）** をバックエンドに適用。ドメインごとにモジュールを分割し、各モジュール内でレイヤー（controller / service / domain / infra）を持つ。

## ディレクトリパターン

### バックエンド: ドメインモジュール
**場所**: `backend/src/domains/{domain}/`
**目的**: ドメインロジックをカプセル化した自己完結モジュール
**例**: `backend/src/domains/user/`

各ドメインは以下のレイヤー構成を持つ:

```
{domain}/
├── {domain}.module.ts      # NestJSモジュール定義・DI設定
├── controller/             # HTTPエンドポイント（入力受付）
├── service/                # ユースケース・ビジネスロジック
├── domain/
│   ├── entity.ts           # ドメインエンティティ（不変クラス）
│   └── interfaces/
│       ├── {domain}.command.interface.ts  # 書き込みリポジトリIF
│       └── {domain}.query.interface.ts   # 読み込みリポジトリIF
└── infra/
    ├── {domain}.command.repository.ts    # Prisma書き込み実装
    └── {domain}.query.repository.ts     # Prisma読み込み実装
```

**現在のドメイン**: `user`, `auth`, `group`, `item`, `request`

### バックエンド: 共通インフラ
**場所**: `backend/src/prisma/`
**目的**: PrismaServiceとPrismaModuleの共有
**パターン**: 各ドメインモジュールがPrismaModuleをimportして利用

**場所**: `backend/src/common/guards/`
**目的**: ドメイン横断のガード（`item-owner.guard.ts`, `group-member.guard.ts`）
**パターン**: 認可ロジックを共通ガードに抽出し、コントローラーデコレータで適用

### auth ドメインの特殊パターン
**場所**: `backend/src/domains/auth/`
**目的**: JWT認証（Passport.js連携）
**構成**: strategies（local/jwt）, guards（jwt-auth）, decorators（@Public, @CurrentUser）
**特記**: 他ドメインと異なりリポジトリを持たず、UserServiceに依存

### フロントエンド
**場所**: `frontend/lib/`
**目的**: Flutterアプリのソースコード
**構成パターン**: feature-based（`features/{domain}/`）+ core層（`core/network/`, `core/models/`）

```
lib/
├── main.dart
├── router.dart
├── core/
│   ├── models/models.dart       # 全モデル定義
│   └── network/
│       ├── api_client.dart      # Dioベースの共通HTTPクライアント
│       └── auth_repository.dart
└── features/
    └── {feature}/
        ├── {feature}_state.dart    # 状態クラス（不変）
        ├── {feature}_provider.dart # Riverpod Provider
        └── {screen}_screen.dart    # UI画面
```

**現在の機能**: `auth`, `group`, `item`, `request`

## 命名規則

### バックエンド（TypeScript）
- **ファイル**: `{domain}.{layer}.{type}.ts`（例: `user.command.repository.ts`）
- **クラス**: PascalCase（例: `UserCommandRepository`）
- **DIトークン**: `'USER_COMMAND_REPOSITORY'`（SCREAMING_SNAKE_CASE文字列）
- **エンティティメソッド**: camelCase、動詞で意図を表現（例: `register()`, `updated()`）

### フロントエンド（Dart）
- **ファイル**: snake_case（Dartの慣例）
- **クラス**: PascalCase

## インポート規則（バックエンド）

```typescript
// 外部ライブラリ
import { Module, Controller, Inject } from '@nestjs/common';

// 同一ドメイン内
import { UserService } from '../service/user.service';

// ドメイン間（共通モジュール）
import { PrismaModule } from '../../../prisma/prisma.module';
```

パスエイリアスは未設定。相対パスを使用。

## コード組織の原則

- **エンティティは不変**: コンストラクタで全フィールドを初期化、変更は新インスタンスを返す
- **リポジトリはCQRS分離**: CommandとQueryを別クラスに実装
- **DI経由でリポジトリ注入**: `@Inject('TOKEN')` パターンで疎結合を保つ
- **Prismaスキーマが単一真実**: `backend/prisma/schema.prisma` がDB構造の唯一の定義元
