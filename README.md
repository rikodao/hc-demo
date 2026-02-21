# SOC2 Compliance Demo - HCP Terraform + Sentinel + Vault

HashiCorp のプラットフォームを活用した **SOC2 Type 2 継続的コンプライアンス** のデモ環境です。

## デモで証明する3つのポイント

| # | テーマ | 使用技術 | 証明すること |
|---|--------|----------|-------------|
| 1 | 予防的統制 | Sentinel | ポリシー違反の自動ブロック |
| 2 | 特権アクセス管理 | Vault + OIDC | 永続的な鍵を持たない動的認証 |
| 3 | 完全な監査証跡 | HCP Terraform Audit | PR → ポリシー → 認証の一気通貫ログ |

## プロジェクト構成

```
.
├── terraform/           # Terraform設定ファイル
│   ├── main.tf          # S3バケットリソース定義
│   ├── variables.tf     # 入力変数
│   ├── outputs.tf       # 出力値
│   ├── providers.tf     # AWSプロバイダ設定
│   └── versions.tf      # Terraform & HCP Cloud設定
├── sentinel/            # Sentinelポリシー
│   ├── sentinel.hcl     # ポリシー設定
│   ├── enforce-s3-encryption.sentinel
│   └── require-public-access-block.sentinel
└── .github/workflows/   # GitHub Actions
    └── terraform.yml    # CI/CDパイプライン
```

## デモ手順

### 事前準備

1. HCP Terraform でワークスペース `soc2-compliance-demo` を作成
2. Sentinel ポリシーセットを設定（`sentinel/` ディレクトリを使用）
3. GitHub リポジトリと HCP Terraform ワークスペースを VCS 連携

### STEP 1: 違反の検知（予防的統制）

```bash
# feature branch を作成（暗号化なしの状態）
git checkout -b feature/add-s3-bucket
git push -u origin feature/add-s3-bucket
```

1. GitHub で `main` への PR を作成
2. HCP Terraform が自動的に Plan を実行
3. **Sentinel が S3 暗号化未設定を検知してブロック** ← ここがポイント

> 「人間がレビューで見逃しても、プラットフォームが物理的に違反を阻止します」

### STEP 2: 動的認証によるデプロイ（特権アクセス管理）

```bash
# 暗号化を有効化して修正コミット
# terraform/variables.tf の enable_encryption を true に変更
git commit -am "fix: enable S3 encryption for SOC2 compliance"
git push
```

1. PR を更新、再度 Plan が実行される
2. **Sentinel ポリシーを PASS**
3. 承認後、HCP Terraform が Vault 経由で一時的な AWS 認証情報を取得
4. 静的なアクセスキーを一切使わずにデプロイ完了

> 「実行の瞬間に Vault から払い出された、数分間だけ有効な一時的権限で動作しています」

### STEP 3: 監査証跡の確認

1. HCP Terraform UI → Runs → 最新の実行を開く
2. 以下が1画面で確認可能:
   - **誰の PR** か（GitHub 連携）
   - **どのポリシーをパス** したか（Sentinel 結果）
   - **どの AWS 権限を使用** したか（Vault 監査ログ）

> 「この1画面がそのまま『証跡レポート』になります」

## 環境変数（必須）

```bash
export TF_CLOUD_ORGANIZATION="your-org-name"
export TF_TOKEN_app_terraform_io="your-tfc-api-token"
```

## セキュリティに関する注意

- このリポジトリは **Public** です
- クレデンシャル（API トークン、アクセスキー等）は絶対にコミットしないでください
- 機密情報は GitHub Secrets または HCP Terraform Variables で管理してください
