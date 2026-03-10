# dbmate-tbls-sqfluff-mysql-sample

MySQL のスキーマ管理リポジトリ。
[dbmate](https://github.com/amacneil/dbmate) によるマイグレーション、[SQLFluff](https://sqlfluff.com/) による SQL lint、[tbls](https://github.com/k1LoW/tbls) によるスキーマドキュメント自動生成を行う。

> **関連リポジトリ**: [nextjs-mysql-sample](https://github.com/s11142/nextjs-mysql-sample)（Web アプリ側）が本リポジトリを Git Submodule として参照している。

---

## 目次

- [前提条件](#前提条件)
- [初期セットアップ](#初期セットアップ)
- [コマンド一覧](#コマンド一覧)
- [ディレクトリ構成](#ディレクトリ構成)
- [運用ガイド](#運用ガイド)
  - [マイグレーションの作成](#マイグレーションの作成)
  - [SQL lint](#sql-lint)
  - [スキーマドキュメント生成](#スキーマドキュメント生成)
  - [ロールバック](#ロールバック)
  - [スキーマダンプ](#スキーマダンプ)
- [SQLFluff ルール](#sqlfluff-ルール)
- [CI/CD](#cicd)
- [接続情報](#接続情報)
- [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

- **Docker** / **Docker Compose**（V2）

ローカルに dbmate や SQLFluff のインストールは不要。全て Docker 経由で実行される。

---

## 初期セットアップ

```bash
# 1. リポジトリをクローン
git clone https://github.com/s11142/dbmate-tbls-sqfluff-mysql-sample.git
cd dbmate-tbls-sqfluff-mysql-sample

# 2. MySQL 起動 + マイグレーション適用
make up

# 3. マイグレーション状態を確認（全て Applied であること）
make status
```

`make up` は以下を順番に実行する:

1. MySQL コンテナをバックグラウンドで起動
2. `dbmate wait` で MySQL の接続受付を待機
3. `dbmate up` で全マイグレーションを適用

---

## コマンド一覧

| コマンド | 説明 |
|---|---|
| `make up` | MySQL 起動 + マイグレーション適用 |
| `make down` | MySQL 停止 + ボリューム削除（データ全消去） |
| `make new NAME=xxx` | 新しいマイグレーションファイルを作成 |
| `make migrate` | 未適用のマイグレーションを適用 |
| `make rollback` | 最後に適用したマイグレーションを1つ巻き戻す |
| `make status` | マイグレーションの適用状態を表示 |
| `make dump` | 現在のスキーマを `db/schema.sql` にダンプ |
| `make lint` | SQLFluff で SQL ファイルを lint |
| `make lint-fix` | SQLFluff で SQL ファイルを自動修正 |
| `make docs` | tbls でスキーマドキュメントを生成 |

---

## ディレクトリ構成

```
dbmate-tbls-sqfluff-mysql-sample/
├── .github/workflows/
│   ├── lint.yml                # SQLFluff lint + 危険コマンドチェック
│   ├── migration-test.yml      # マイグレーション往復テスト
│   └── generate-docs.yml       # tbls ドキュメント自動生成
├── db/
│   ├── migrations/             # マイグレーションファイル（タイムスタンプ付き）
│   └── schema.sql              # dbmate dump で自動生成されるスキーマ
├── docs/schema/                # tbls が自動生成するドキュメント（Markdown + SVG）
├── .sqlfluff                   # SQLFluff 設定
├── .tbls.yml                   # tbls 設定
├── docker-compose.yml          # MySQL 8.0 + dbmate サービス定義
└── Makefile                    # 操作コマンド集
```

---

## 運用ガイド

### マイグレーションの作成

```bash
# 1. マイグレーションファイルを生成
make new NAME=create_orders_table
# → db/migrations/20260310123456_create_orders_table.sql が作成される

# 2. 生成されたファイルを編集
```

マイグレーションファイルの書式:

```sql
-- migrate:up
CREATE TABLE orders (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    total INT UNSIGNED NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_user_id FOREIGN KEY (user_id) REFERENCES users (id)
);

-- migrate:down
DROP TABLE IF EXISTS orders;
```

- `-- migrate:up` と `-- migrate:down` の両方を必ず記述する
- `down` にはロールバック用の SQL を書く（テーブル作成なら `DROP TABLE`）
- 1ファイルにつき1つの論理的な変更にまとめる

```bash
# 3. lint で構文チェック
make lint

# 4. 適用して動作確認
make migrate

# 5. ロールバックの動作も確認
make rollback
make migrate
```

### SQL lint

```bash
# チェックのみ（CI と同じ）
make lint

# 自動修正
make lint-fix
```

SQLFluff が Docker で実行され、`db/migrations/` 配下の全 `.sql` ファイルをチェックする。
自動修正できない違反がある場合は手動で修正すること。

### スキーマドキュメント生成

```bash
# MySQL が起動している状態で実行
make docs
```

`docs/schema/` 配下に以下が生成される:

- `README.md` — テーブル一覧
- `{テーブル名}.md` — 各テーブルのカラム定義・インデックス・外部キー
- `*.svg` — ER 図

> main ブランチへのマージ時に GitHub Actions が自動でドキュメントを生成・コミットするため、通常は手動実行不要。

### ロールバック

```bash
# 最後の1つを巻き戻す
make rollback

# 複数巻き戻す場合は繰り返し実行
make rollback
make rollback
```

`make rollback` は1回につき直近1つのマイグレーションを巻き戻す。

### スキーマダンプ

```bash
make dump
# → db/schema.sql が更新される
```

`db/schema.sql` は dbmate が管理するスキーマの全体像。現在の DB 状態をファイルに書き出す。
差分レビューやスキーマ全体の俯瞰に利用できる。

---

## SQLFluff ルール

`.sqlfluff` で以下のルールを設定している:

| 設定 | 値 | 説明 |
|---|---|---|
| `dialect` | `mysql` | MySQL 構文として解析 |
| `max_line_length` | `120` | 1行あたりの最大文字数 |
| `capitalisation.keywords` | `upper` | `SELECT`, `CREATE` 等のキーワードは大文字 |
| `capitalisation.types` | `upper` | `BIGINT`, `VARCHAR` 等の型名は大文字 |
| `convention.terminator` | `require_final_semicolon` | 文末にセミコロン必須 |

---

## CI/CD

### lint.yml — SQL lint（PR 時）

**トリガー**: `db/migrations/**` に変更がある Pull Request

1. **SQLFluff lint**: マイグレーションファイルの構文・規約チェック
2. **危険コマンドチェック**: `-- migrate:up` セクション内の `DROP TABLE` / `TRUNCATE` / `DROP DATABASE` を検出して警告を出す（`-- migrate:down` 内は許可）

### migration-test.yml — マイグレーション往復テスト（PR 時）

**トリガー**: `db/migrations/**` に変更がある Pull Request

1. Service Container で MySQL 8.0 を起動
2. `dbmate up` — 全マイグレーション適用
3. 全マイグレーションを1つずつ `dbmate rollback`
4. `dbmate up` — 再度全適用

up → rollback → up の往復が成功することを検証する。

### generate-docs.yml — ドキュメント自動生成（main マージ時）

**トリガー**: main ブランチへの push で `db/migrations/**` に変更がある場合

1. MySQL 起動 + マイグレーション適用
2. `tbls doc --force` でスキーマドキュメント生成
3. 変更があれば `docs/schema/` を自動コミット・プッシュ

---

## 接続情報

| 項目 | 値 |
|---|---|
| Host | `127.0.0.1` |
| Port | `3306` |
| Database | `app_db` |
| User | `app_user` |
| Password | `app_pass` |
| Root Password | `rootpass` |

MySQL クライアントから接続する場合:

```bash
docker compose exec mysql mysql -u app_user -papp_pass app_db
```

---

## トラブルシューティング

### `make up` でポート 3306 が既に使用中

```
Error: Bind for 0.0.0.0:3306 failed: port is already allocated
```

別のプロセスが 3306 を使用している。以下で確認:

```bash
lsof -i :3306
```

他の MySQL コンテナが起動している場合は停止してから再実行する。
特に [nextjs-mysql-sample](https://github.com/s11142/nextjs-mysql-sample) の MySQL と同じポートを使うため、同時起動はできない。

### `make lint` で Docker イメージのプルに失敗

初回は SQLFluff の Docker イメージをダウンロードするため、ネットワーク接続が必要。

### `make docs` で接続エラー

tbls は `--network host` でホストの MySQL に接続するため、`make up` で MySQL が起動していることを確認してから実行する。

### dbmate の `unexpected EOF` エラー

MySQL が起動直後で接続を受け付けていない。`make up` は `dbmate wait` を含むので通常は発生しないが、`make migrate` を直接実行した場合に起こりうる。MySQL コンテナの healthcheck が完了するまで待つこと。
