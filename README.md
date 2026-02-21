# SOC2 Compliance Demo - HCP Terraform + Sentinel + Vault

HashiCorp プラットフォームを活用した **SOC2 Type 2 継続的コンプライアンス** のデモ環境です。

## デモで証明する3つのポイント

| # | テーマ | 使用技術 | 証明すること |
|---|--------|----------|-------------|
| 1 | 予防的統制 | Sentinel | ポリシー違反の自動ブロック |
| 2 | 特権アクセス管理 | Vault + OIDC | 永続的な鍵を持たない動的認証 |
| 3 | 完全な監査証跡 | HCP Terraform Audit | PR → ポリシー → 認証の一気通貫ログ |

## プロジェクト構成

```
.
├── terraform/              # Terraform設定ファイル
│   ├── main.tf             # S3バケットリソース定義
│   ├── variables.tf        # 入力変数（enable_encryption トグル）
│   ├── outputs.tf          # 出力値
│   ├── providers.tf        # AWSプロバイダ設定
│   └── versions.tf         # Terraform & HCP Cloud設定
├── sentinel/               # Sentinelポリシー
│   ├── sentinel.hcl        # ポリシーセット設定
│   ├── enforce-s3-encryption.sentinel
│   └── require-public-access-block.sentinel
├── bootstrap/              # HCP Terraform ワークスペース設定
│   └── main.tf             # TFC Org/Workspace/Sentinel 自動構築
├── scripts/                # デモ用スクリプト
│   ├── setup.sh            # 初期セットアップ
│   ├── demo-step1-violation.sh
│   ├── demo-step2-fix-deploy.sh
│   └── demo-step3-audit.sh
└── .github/workflows/
    └── terraform.yml       # CI/CDパイプライン
```

## セットアップ手順

### 前提条件

1. HCP アカウントとサービスプリンシパル
2. GitHub リポジトリ（このリポジトリ）
3. AWS アカウント（デプロイ対象）

### Step 0: HCP Terraform の有効化（手動・1回のみ）

1. [HCP Portal](https://portal.cloud.hashicorp.com) にログイン
2. **Services → Terraform** を選択
3. **Create a Terraform organization** をクリック
4. Organization名: `rikodao-org`（HCP組織名と同じ）

### Step 1: 環境変数の設定

```bash
export HCP_CLIENT_ID="your-client-id"
export HCP_CLIENT_SECRET="your-client-secret"
export TF_VAR_github_token="your-github-token"
export TF_VAR_hcp_project_id="your-hcp-project-id"
```

### Step 2: 自動セットアップ

```bash
./scripts/setup.sh
```

このスクリプトは以下を自動構築します:
- HCP Terraform ワークスペース (`soc2-compliance-demo`)
- GitHub VCS 連携（OAuth）
- Sentinel ポリシーセット（S3暗号化強制 + パブリックアクセス禁止）

## デモ実行手順

### STEP 1: 違反の検知 ～ 予防的統制（2分）

```bash
./scripts/demo-step1-violation.sh
```

1. 暗号化なしのS3バケット設定でブランチを作成
2. GitHub で `main` への PR を作成
3. HCP Terraform が自動的に Plan を実行
4. **Sentinel が暗号化未設定を検知 → デプロイをブロック**

> 「人間がレビューで見逃しても、プラットフォームが物理的に違反を阻止します。
>  これがSOC2で求められる『継続的な統制』の実装です。」

### STEP 2: 修正 & 動的認証デプロイ（5分）

```bash
./scripts/demo-step2-fix-deploy.sh
```

1. 暗号化を有効化して修正コミット
2. Sentinel ポリシーを PASS
3. HCP Terraform が **Vault 経由で一時的な AWS 認証情報を取得**
4. 静的なアクセスキーなしでデプロイ完了

> 「GitHub Actions や HCP Terraform に『永続的な鍵』は保存されていません。
>  実行の瞬間に Vault から払い出された、数分間だけ有効な一時的な権限で動作しています。」

### STEP 3: 監査証跡の確認（3分）

```bash
./scripts/demo-step3-audit.sh
```

HCP Terraform UI で以下が1画面で確認可能:
- **誰のPR** か（GitHub 連携）
- **どのポリシーをパス** したか（Sentinel 結果）
- **どの AWS 権限を使用** したか（Vault 監査ログ）

> 「監査対応時に CloudTrail を数時間かけて検索する必要はありません。
>  この1画面がそのまま『証跡レポート』になります。」

## セキュリティに関する注意

- このリポジトリは **Public** です
- クレデンシャル（API トークン、アクセスキー等）は絶対にコミットしないでください
- 機密情報は GitHub Secrets または HCP Terraform Variables で管理してください
