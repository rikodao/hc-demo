# 作業レポート: SOC2 コンプライアンスデモ環境構築

**作成日**: 2026年2月22日  
**対象リポジトリ**: https://github.com/rikodao/hc-demo  
**HCP組織**: rikodao-org  
**HCPプロジェクトID**: cba99d6c-8bdf-47f7-a792-28fba8805b12

---

## 1. 目的

NextPay様向けの SOC2 Type 2 コンプライアンスデモ環境を構築する。  
HashiCorp のプラットフォーム（HCP Terraform / Sentinel / Vault）を使い、以下の3点を実証する:

| # | 証明テーマ | 使用技術 |
|---|-----------|---------|
| 1 | 予防的統制 | Sentinel ポリシーによるデプロイブロック |
| 2 | 特権アクセス管理 | Vault OIDC 連携による動的認証 |
| 3 | 完全な監査証跡 | HCP Terraform の統合ログ |

---

## 2. 実施した作業

### 2.1 プロジェクト構造の作成

GitHubリポジトリ `rikodao/hc-demo` を初期化し、以下のディレクトリ構成を構築した。

```
hc-demo/
├── terraform/                  # インフラ定義
│   ├── main.tf                 # S3バケットリソース（暗号化トグル付き）
│   ├── variables.tf            # 入力変数（enable_encryption等）
│   ├── outputs.tf              # 出力値（ARN, バケット名）
│   ├── providers.tf            # AWSプロバイダ + デフォルトタグ
│   ├── versions.tf             # Terraform Cloud接続設定
│   └── terraform.tf.example    # 変数ファイルのサンプル
├── sentinel/                   # ポリシー定義
│   ├── sentinel.hcl            # ポリシーセット設定
│   ├── enforce-s3-encryption.sentinel
│   └── require-public-access-block.sentinel
├── bootstrap/                  # TFC自動セットアップ
│   └── main.tf                 # ワークスペース/Sentinel/VCS連携
├── scripts/                    # デモ用スクリプト
│   ├── setup.sh                # 初期セットアップ自動化
│   ├── demo-step1-violation.sh # STEP1: 違反検知
│   ├── demo-step2-fix-deploy.sh# STEP2: 修正デプロイ
│   └── demo-step3-audit.sh     # STEP3: 監査証跡
├── .github/workflows/
│   └── terraform.yml           # GitHub Actions CI/CD
├── .gitignore
└── README.md
```

### 2.2 Terraform 設定ファイルの作成

**`terraform/main.tf`** に以下のリソースを定義:

| リソース | 説明 |
|---------|------|
| `aws_s3_bucket.data_store` | 顧客データ用バケット |
| `aws_s3_bucket_versioning.data_store` | バージョニング有効化 |
| `aws_s3_bucket_public_access_block.data_store` | パブリックアクセス完全ブロック |
| `aws_s3_bucket_server_side_encryption_configuration.data_store` | KMS暗号化（**条件付き: `enable_encryption`変数で制御**） |
| `aws_s3_bucket.access_logs` | 監査ログ用バケット |
| `aws_s3_bucket_server_side_encryption_configuration.access_logs` | ログバケットのKMS暗号化 |
| `aws_s3_bucket_logging.data_store` | アクセスログの出力設定 |

デモのポイントとして、`enable_encryption` 変数を `false`（デフォルト）にすることで、データバケットの暗号化を意図的に省略できる設計にした。これにより Sentinel が違反を検知するシナリオを再現できる。

### 2.3 Sentinel ポリシーの作成

2つのポリシーを `hard-mandatory`（上書き不可）で作成:

**ポリシー1: `enforce-s3-encryption.sentinel`**
- S3バケット数と暗号化設定数を比較
- バケットに対して暗号化設定がない場合、Plan を強制的にブロック

**ポリシー2: `require-public-access-block.sentinel`**
- すべてのS3バケットに対し、4つのパブリックアクセスブロック項目が `true` であることを検証
- 1つでも `false` の場合はブロック

### 2.4 GitHub Actions ワークフローの作成

**`.github/workflows/terraform.yml`**:
- PR作成時: `terraform plan` を実行し、結果をPRコメントに投稿
- main マージ時: `terraform apply` を自動実行
- OIDC `id-token: write` パーミッションを付与（Vault動的認証用）

### 2.5 Bootstrap（TFC自動セットアップ）の作成

**`bootstrap/main.tf`** で以下を自動構築する Terraform 設定を作成:

| リソース | 説明 |
|---------|------|
| `tfe_oauth_client.github` | GitHub VCS連携（OAuthクライアント） |
| `tfe_workspace.soc2_demo` | ワークスペース `soc2-compliance-demo` |
| `tfe_policy_set.sentinel` | Sentinelポリシーセット（VCS連携） |

HCPプロバイダとTFEプロバイダの両方を使用し、HCPサービスプリンシパルの認証情報で動作する。

### 2.6 Git ブランチ戦略とPRの作成

以下のコミット履歴を構築:

```
* 6319a4e (main) Add bootstrap, demo scripts, and comprehensive README
| * e799ed7 (feature/add-s3-data-store) fix: enable S3 server-side encryption for SOC2 compliance
| * 8a684da feat: add S3 data store bucket for customer data
|/
* aa9e000 Initial commit: SOC2 compliance demo with HCP Terraform + Sentinel
```

- **PR #1**: `feature/add-s3-data-store` → `main`
  - 1コミット目: 暗号化なし（Sentinelでブロックされるデモ用）
  - 2コミット目: 暗号化有効化（修正後のデモ用）

### 2.7 HCP 認証の検証

HCPサービスプリンシパル（プロジェクトスコープ）での認証を検証:

| 操作 | 結果 |
|------|------|
| HCP OAuth トークン取得 | 成功 |
| HCP組織情報取得 | 成功（`rikodao-org`） |
| HCPプロジェクト情報取得 | 成功（`default-project`） |
| TFC組織作成 | **未完了**（`tfc_synced: false` のため） |
| TFC API 直接アクセス | 不可（HCPトークンではTFC APIに認証不可） |

---

## 3. 現在の状態と残作業

### 完了済み

- [x] Terraform 設定ファイル一式（S3バケット、暗号化トグル）
- [x] Sentinel ポリシー2本（暗号化強制、パブリックアクセスブロック強制）
- [x] GitHub Actions CI/CD ワークフロー
- [x] Bootstrap 自動セットアップ設定
- [x] デモ用シェルスクリプト3本 + セットアップスクリプト
- [x] GitHubリポジトリへのプッシュ
- [x] PR #1 の作成（デモ用ブランチ）

### 残作業（手動ステップ: 1つ）

- [ ] **HCP Terraform 組織の有効化**

HCP組織 `rikodao-org` の `tfc_synced` が `false` のため、TFC組織がまだ存在しない。  
以下の手順で有効化が必要:

1. [HCP Portal](https://portal.cloud.hashicorp.com) にログイン
2. **Services → Terraform** を選択
3. **Create a Terraform organization** で `rikodao-org` を作成
4. 作成後、`./scripts/setup.sh` を実行

### 有効化後に自動実行されること

`setup.sh` 実行により:
1. HCP認証 → TFEトークン取得
2. TFCワークスペース `soc2-compliance-demo` 作成
3. GitHub VCS連携（OAuth）設定
4. Sentinelポリシーセット適用

---

## 4. セキュリティ考慮事項

- リポジトリは **Public** であるため、クレデンシャルは一切コミットしていない
- `.gitignore` で `*.tfvars`, `.terraform/`, `terraform.tfstate*`, `credentials.tfrc.json` を除外
- HCPサービスプリンシパルのClient ID/Secretは環境変数でのみ使用
- GitHubトークンは `TF_VAR_github_token` 環境変数でのみ使用
- 全コミット前にクレデンシャルスキャンを実施し、混入がないことを確認済み
