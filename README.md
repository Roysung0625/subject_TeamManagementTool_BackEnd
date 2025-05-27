# Team Task Manager

データⅩ エンジニア選考課題として開発した簡易SaaS型タスク共有ツールです。

## 📋 プロジェクト概要

### 目的
Ruby on Rails を用いて、チーム単位でタスクを管理・共有できるSaaSツールを開発しました。JWT認証によるセキュアなAPI設計と、サービス層を活用したクリーンアーキテクチャを採用しています。

### 主要機能
- ✅ **ユーザー認証** - JWT トークンベースの認証（サインアップ・ログイン・ログアウト）
- 🏢 **チーム管理** - ユーザーは複数チームに所属可能、Admin権限による管理
- 📝 **タスク管理** - 作成・編集・削除・完了状態切り替え
- 🔍 **フィルタリング機能** - 担当者・カテゴリ・ステータス別の絞り込み
- 📊 **ページネーション** - 大量データの効率的な表示
- 🔐 **権限管理** - Admin/Employee ロールベースのアクセス制御

## 🛠 技術スタック

### バックエンド
- **Ruby** 3.2.0
- **Rails** 8.0.2 (APIモード)
- **SQLite3** - 開発・テスト環境
- **PostgreSQL** - 本番環境対応

### 認証・セキュリティ
- **JWT** - トークンベース認証
- **bcrypt** - パスワードハッシュ化
- **rack-cors** - CORS対応

### テスト・開発ツール
- **Minitest** - 標準テストフレームワーク
- **FactoryBot** - テストデータ生成
- **Faker** - ダミーデータ生成

### その他
- **active_model_serializers** - JSON レスポンス整形
- **dotenv-rails** - 環境変数管理

## 🏗 アーキテクチャ設計

### レイヤー構成

Controller → Service → Model → Database


- **Controller層**: HTTP リクエスト処理、認証・認可
- **Service層**: ビジネスロジック、複雑な処理の集約
- **Model層**: データ検証、リレーション定義
- **DTO層**: レスポンス形式の統一

### リレーション
- Employee ↔ Team: 多対多 (EmployeeTeam経由)
- Employee → Task: 一対多
- Team → Task: Team経由でEmployeeのTaskにアクセス

## 🚀 セットアップ・実行方法

### 前提条件
- Ruby 3.2.0
- Rails 8.0.2
- SQLite3

### インストール手順

1. **リポジトリクローン**
```bash
git clone <repository-url>
cd TeamManagementTool
```

2. **依存関係インストール**
```bash
bundle install
```

3. **環境変数設定**
```bash
# .env ファイルを作成
echo "JWT_SECRET_KEY=your_secret_key_here" > .env
```

4. **データベース設定**
```bash
rails db:create
rails db:migrate
rails db:seed
```

5. **サーバー起動**
```bash
rails server
```

### テスト実行
```bash
# 全テスト実行
rails test

# 特定のテストファイル実行
rails test test/controllers/auth_controller_test.rb
rails test test/controllers/teams_controller_test.rb
rails test test/controllers/tasks_controller_test.rb
```

## 📡 API仕様

### 認証API (3エンドポイント)
| Method | Endpoint | 説明 | 権限 |
|--------|----------|------|------|
| POST | `/api/auth/register` | ユーザー登録 | - |
| POST | `/api/auth/login` | ログイン | - |
| POST | `/api/auth/logout` | ログアウト | 認証必須 |

### チーム管理API (6エンドポイント)
| Method | Endpoint | 説明 | 権限 |
|--------|----------|------|------|
| POST | `/api/teams` | チーム作成 | Admin |
| PATCH | `/api/teams/:id` | チーム更新 | Admin |
| DELETE | `/api/teams/:id` | チーム削除 | Admin |
| GET | `/api/teams/team/:team_id` | チームメンバー一覧 | チームメンバー |
| PATCH | `/api/teams/management/:team_id` | メンバー管理 | Admin |
| GET | `/api/teams/employee/:employee_id` | 従業員の所属チーム一覧 | 本人またはAdmin |

### タスク管理API (8エンドポイント)
| Method | Endpoint | 説明 | 権限 |
|--------|----------|------|------|
| POST | `/api/tasks` | タスク作成 | 認証必須 |
| PATCH | `/api/tasks/:id` | タスク更新 | 作成者またはAdmin |
| DELETE | `/api/tasks/:id` | タスク削除 | 作成者またはAdmin |
| GET | `/api/tasks/:id` | タスク詳細 | 認証必須 |
| GET | `/api/tasks/employee/:employee_id/today` | 本日のタスク | 本人またはAdmin |
| GET | `/api/tasks/employee/:employee_id` | 全タスク(ページング) | 本人またはAdmin |
| GET | `/api/tasks/team/:team_id` | チームタスク(フィルタ+ページング) | チームメンバー |
| GET | `/api/tasks/team/:team_id/today` | チーム本日タスク | チームメンバー |

### リクエスト例

#### ログイン
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name": "admin", "password": "password"}'
```

#### タスク作成
```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "新しいタスク",
    "detail": "タスクの詳細",
    "category": "開発",
    "status": "pending",
    "due": "2024-12-31T23:59:59Z",
    "employee_id": 1
  }'
```

#### チームタスク取得（フィルタリング）
```bash
curl "http://localhost:3000/api/tasks/team/1?category=開発&status=pending&offset=0" \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

## 🧪 テスト設計

### テストカバレッジ
- **認証テスト**: 登録・ログイン・ログアウト機能
- **チーム管理テスト**: CRUD操作、権限検証
- **タスク管理テスト**: CRUD操作、フィルタリング、ページネーション
- **権限テスト**: Admin/Employee ロール別アクセス制御

### 主要テストケース

#### 認証テスト
- ✅ 正常な登録・ログイン
- ✅ 不正な認証情報での失敗
- ✅ JWT トークンの有効期限検証

#### 権限テスト
- ✅ Admin権限でのチーム管理
- ✅ 一般ユーザーの権限制限
- ✅ 他人のタスクへのアクセス制限

#### ビジネスロジックテスト
- ✅ タスクのバリデーション
- ✅ チームメンバー管理
- ✅ フィルタリング・ページネーション

## 🔒 セキュリティ対策

### 実装済み対策
- **JWT認証**: トークンベースの認証、有効期限管理
- **パスワードハッシュ化**: bcrypt による安全な保存
- **権限ベースアクセス制御**: Admin/Employee ロール管理
- **入力値検証**: モデルレベルでのバリデーション
- **SQL Injection対策**: ActiveRecord ORM使用

### JWT設定
- **有効期限**: 24時間
- **自動検証**: 期限切れトークンの自動拒否
- **エラーハンドリング**: 詳細なエラーレスポンス

## 📈 今後の拡張予定

### 機能拡張
- [ ] **バッチ処理**: Rakeタスクによるタスク進捗率集計
- [ ] **通知機能**: タスク期限アラート
- [ ] **ファイル添付**: タスクへのファイル添付機能
- [ ] **コメント機能**: タスクへのコメント・履歴管理

### 技術的改善
- [ ] **フロントエンド**: Vue.js 3 + Vite による SPA 開発
- [ ] **リアルタイム**: Action Cable によるリアルタイム更新
- [ ] **API文書化**: Swagger/OpenAPI による自動文書生成
- [ ] **監視**: ログ集約・メトリクス収集

## 🤝 開発・運用

### 開発フロー
1. **設計**: API設計 → モデル設計 → サービス層設計
2. **実装**: TDD アプローチでテスト先行開発
3. **検証**: 手動テスト → 自動テスト → セキュリティチェック

### コード品質
- **Rubocop**: コーディング規約準拠
- **Brakeman**: セキュリティ脆弱性検査
- **テストカバレッジ**: 主要機能の網羅的テスト

## 📝 ライセンス

このプロジェクトは学習・評価目的で作成されました。

---

**開発者**: [ソン　ジョンヒョン]  
**作成日**: 2025年 5月28日  
**課題**: データⅩ エンジニア選考課題
