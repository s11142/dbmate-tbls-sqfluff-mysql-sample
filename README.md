# dbmate-tbls-sqfluff-mysql-sample

MySQL のマイグレーション管理リポジトリ。dbmate によるマイグレーション、SQLFluff による SQL lint、tbls によるスキーマドキュメント自動生成を行う。

## 前提条件

- Docker / Docker Compose

## クイックスタート

```bash
# MySQL起動 + マイグレーション適用
make up

# マイグレーション状態確認
make status

# 新しいマイグレーション作成
make new NAME=create_xxx_table

# SQL lint
make lint

# スキーマドキュメント生成
make docs

# ロールバック
make rollback

# 全停止・データ削除
make down
```

## ディレクトリ構成

```
├── db/
│   ├── migrations/     # dbmate マイグレーションファイル
│   └── schema.sql      # dbmate dump で自動生成
├── docs/schema/        # tbls 自動生成ドキュメント
├── .sqlfluff           # SQLFluff 設定
├── .tbls.yml           # tbls 設定
├── docker-compose.yml  # MySQL + dbmate
└── Makefile            # 操作コマンド集
```

## CI/CD

| ワークフロー | トリガー | 内容 |
|---|---|---|
| `lint.yml` | PR（migrations変更時） | SQLFluff lint + 危険コマンドチェック |
| `migration-test.yml` | PR（migrations変更時） | マイグレーション往復テスト |
| `generate-docs.yml` | mainマージ（migrations変更時） | tbls ドキュメント自動生成・コミット |

## 接続情報（開発用）

| 項目 | 値 |
|---|---|
| Host | 127.0.0.1 |
| Port | 3306 |
| Database | app_db |
| User | app_user |
| Password | app_pass |
