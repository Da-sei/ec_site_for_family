---
inclusion: always
---

# 技術スタック

## アーキテクチャ

- **バックエンド**: REST API（NestJS）+ PostgreSQL（Prisma ORM）
- **フロントエンド**: Flutter モバイルアプリ（iOS/Android/Web対応）
- **インフラ**: Docker Compose（PostgreSQL + バックエンドコンテナ）

## コア技術

| レイヤー | 技術 |
|---|---|
| 言語（BE） | TypeScript 5.7+ |
| フレームワーク（BE） | NestJS 11 |
| ORM | Prisma 7 |
| DB | PostgreSQL 16 |
| 言語（FE） | Dart (SDK ^3.10.1) |
| フレームワーク（FE） | Flutter |

## 主要ライブラリ（バックエンド）

- `@nestjs/common`, `@nestjs/core`: NestJSコア
- `@prisma/client`, `@prisma/adapter-pg`: DBアクセス
- `@nestjs/jwt`, `passport`, `passport-local`, `passport-jwt`: JWT認証
- `rxjs`: 非同期処理
- `jest`, `supertest`: テスト

## 主要ライブラリ（フロントエンド）

- `flutter_riverpod`: 状態管理
- `dio`: HTTPクライアント
- `go_router`: ルーティング
- `flutter_secure_storage`: JWTトークンのセキュアな永続化
- `image_picker`: 画像選択
- `share_plus`: 招待リンク共有

## 開発標準

### 型安全性
- TypeScript strict モード使用
- `any` 型の使用禁止

### コード品質
- ESLint + Prettier（NestJS デフォルト設定）
- フォーマット: `npm run format`
- Lint: `npm run lint`

### テスト
- Jest（ユニット・E2Eテスト）
- テストファイル: `*.spec.ts`
- E2E設定: `test/jest-e2e.json`

## 開発環境

### 必須ツール
- Node.js（LTS推奨）
- Flutter SDK（^3.10.1）
- Docker & Docker Compose
- Prisma CLI

### 主要コマンド（バックエンド）
```bash
# 開発サーバー起動
npm run start:dev

# ビルド
npm run build

# テスト
npm run test

# DB起動（Docker）
docker compose up -d db
```

### 主要コマンド（フロントエンド）
```bash
# 依存関係インストール
flutter pub get

# 開発実行
flutter run

# テスト
flutter test
```

## 重要な技術的決定

- **CQRSパターン（userドメインのみ）**: `user` ドメインはCommandRepository（書き込み）とQueryRepository（読み込み）を分離。他のドメイン（group, item, request）は単一の `IXxxRepository` を使用
- **JWT認証**: Passport.js（`passport-local` + `passport-jwt`）+ `@nestjs/jwt`。`@Public()` デコレータで認証スキップ制御
- **DIトークン**: NestJS の `@Inject('TOKEN')` でリポジトリをDI
- **Prismaスキーマ**: 単一の `backend/prisma/schema.prisma` で全モデルを管理
- **ポート設定**: バックエンドはホスト3000番→コンテナ3001番にマッピング
- **フロントエンド状態管理**: Riverpod（`flutter_riverpod`）。StateNotifierProvider パターンで状態を管理
- **フロントエンドルーティング**: `go_router` によるDeclarativeルーティング
- **フロントエンドHTTP**: `dio` + `flutter_secure_storage`（JWTトークン保存）
