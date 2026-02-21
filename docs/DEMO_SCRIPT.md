# デモ実演スクリプト & プレゼンターガイド

**想定時間**: 約10分  
**対象**: NextPay様（SOC2 Type 2 対応検討中）  
**心構え**: 「監査官を横に座らせている」つもりで実施する

---

## 事前準備チェックリスト

デモ当日に確認すること:

- [ ] HCP Terraform にログインし、ワークスペースが表示されることを確認
- [ ] GitHub リポジトリ https://github.com/rikodao/hc-demo が開けることを確認
- [ ] ブラウザタブを3つ準備:
  - **タブ1**: GitHub PR画面
  - **タブ2**: HCP Terraform ワークスペース画面
  - **タブ3**: ターミナル（git操作用）
- [ ] ターミナルのフォントサイズを大きくしておく（聴衆が見えるように）

---

## オープニング（1分）

### 話すこと

> 本日は、HashiCorpのプラットフォームを使ったSOC2 Type 2コンプライアンスの実装をデモでお見せします。
>
> これから3つのシナリオをお見せしますが、すべて**実際の環境**で動作しているものです。
>
> 1つ目は「ルール違反を自動的に止められるか」
> 2つ目は「危険な管理者キーを持たずにデプロイできるか」
> 3つ目は「監査で求められるエビデンスが自動で揃うか」
>
> では始めます。

---

## STEP 1: 違反の検知 ― 予防的統制の証明（2分）

### シナリオ説明

> まず、エンジニアが誤ってセキュリティ設定を忘れたケースを再現します。
> S3バケットを作成するコードを書いたのですが、**暗号化の設定を入れ忘れています**。

### 操作手順

#### 1-1. ターミナルで操作

```bash
cd /home/naotoiso/workspace/hashicorp

# 暗号化なしのブランチを作成
git checkout main
git checkout -b demo/missing-encryption

# 暗号化を無効化
sed -i 's/default     = true/default     = false/' terraform/variables.tf

# コミット & プッシュ
git add -A
git commit -m "feat: add S3 bucket for customer data"
git push -u origin demo/missing-encryption
```

#### 1-2. GitHubでPR作成

1. **タブ1（GitHub）** を開く
2. https://github.com/rikodao/hc-demo/pull/new/demo/missing-encryption にアクセス
3. PRタイトル: `feat: Add S3 data store for customer payment data`
4. **Create pull request** をクリック

#### 1-3. HCP Terraform の画面を見せる

1. **タブ2（HCP Terraform）** に切り替え
2. ワークスペース `soc2-compliance-demo` → **Runs** を開く
3. 自動的に Plan が開始されるのを待つ
4. **Policy Check** セクションまでスクロール

### 見せるポイント

> **（Sentinel の FAIL 画面を指して）**
>
> ご覧ください。HCP Terraformが自動的にこのコードを「組織のセキュリティルール」に照らしてチェックし、
> **暗号化設定がないことを検知して、デプロイを拒否しました**。
>
> ポリシー名は `enforce-s3-encryption`。このポリシーは `hard-mandatory`、つまり
> **誰であっても、たとえ管理者であっても、このルールを上書きしてデプロイすることはできません**。

### 決めゼリフ

> 「人間がコードレビューで見逃しても、プラットフォームが**物理的に**違反を阻止します。
> これがSOC2で求められる『**継続的な統制**』の実装です。」

---

## STEP 2: 動的認証によるデプロイ ― 特権アクセス管理の証明（5分）

### シナリオ説明

> 次に、セキュリティ設定を修正して、正しくデプロイできることをお見せします。
> ここで重要なのは、「**どうやって AWS にアクセスしているか**」です。

### 操作手順

#### 2-1. ターミナルで修正コミット

```bash
# 暗号化を有効化
sed -i 's/default     = false/default     = true/' terraform/variables.tf

# 差分を見せる（画面共有時に効果的）
git diff terraform/variables.tf

# コミット & プッシュ
git add -A
git commit -m "fix: enable S3 server-side encryption for SOC2 compliance"
git push
```

#### 2-2. GitHub PR で差分を見せる

1. **タブ1（GitHub）** に戻る
2. PR のコミット一覧で修正内容を表示
3. `enable_encryption` が `false` → `true` に変わっていることを指す

> ご覧のように、変更はたった1行です。暗号化を有効にしました。

#### 2-3. HCP Terraform で再実行を確認

1. **タブ2（HCP Terraform）** に切り替え
2. 新しい Run が自動開始されるのを確認
3. **Policy Check** セクションを表示

### 見せるポイント（Sentinel PASS）

> **（Policy Check が PASS した画面を指して）**
>
> 今度はすべてのポリシーをパスしました。
> - `enforce-s3-encryption`: **Passed**
> - `require-public-access-block`: **Passed**

### 見せるポイント（動的認証）

> **（Plan/Apply ログを開いて）**
>
> ここが今日のデモで**最も重要なポイント**です。
>
> この実行ログをよく見てください。
> **AWS のアクセスキーやシークレットキーが、どこにも登場しません**。

> これは、HCP TerraformがVaultに対してOIDCで認証し、
> **実行の瞬間にだけ有効な一時的なAWS認証情報**を受け取って動作しているからです。

### 決めゼリフ

> 「GitHub ActionsにもHCP Terraformにも、**永続的な鍵は一切保存されていません**。
> 実行の瞬間にVaultから払い出された、**数分間だけ有効な一時的な権限**で動作しています。
> 鍵の漏洩リスクは**実質ゼロ**です。」

---

## STEP 3: 完全な監査証跡の確認（3分）

### シナリオ説明

> 最後に、今行った一連の操作を**監査の視点**から見直します。
> SOC2 Type 2では、「いつ・誰が・何を・どの権限で行ったか」の証跡が必要です。

### 操作手順

#### 3-1. HCP Terraform Run 詳細画面

1. **タブ2（HCP Terraform）** → 最新の Run をクリック
2. Run の詳細画面を上から順に見せる

### 見せるポイント 1: 誰のPRか

> **（Triggered by セクションを指して）**
>
> まず、この実行が**誰のPull Requestで発動したか**がここに記録されています。
> GitHubとの連携により、操作者の特定が自動的に行われています。

### 見せるポイント 2: どのポリシーをパスしたか

> **（Policy Check セクションを指して）**
>
> 次に、**どのセキュリティポリシーを通過したか**がここに一覧で表示されています。
> STEP 1で違反を検知したのと同じポリシーが、修正後に正しくパスしたことが記録されています。

### 見せるポイント 3: どの権限で実行されたか

> **（Apply ログ / Vault連携部分を指して）**
>
> そして、**どの一時的なAWS権限で実行されたか**。
> Vaultの監査ログと合わせることで、この実行で使われた認証情報のライフサイクル全体が追跡可能です。

### 決めゼリフ

> 「監査対応時にCloudTrailを数時間かけて検索する必要はありません。
> **この1画面がそのまま『証跡レポート』になります**。
>
> PRの承認からVaultの認証履歴まで、**すべてが統合されています**。
> これがNextPay様がSOC2 Type 2を**継続的に維持するための『自動エビデンス』**です。」

---

## クロージング（1分）

### まとめ

> 本日お見せしたのは3つのポイントです。

| 画面を切り替えながら | 伝えること |
|---|---|
| Sentinel FAIL 画面 | 「**ルール違反は自動でブロック** ― 予防的統制」 |
| 実行ログ（鍵なし） | 「**永続的な鍵は不要** ― 動的認証による特権アクセス管理」 |
| Run 詳細画面 | 「**証跡は自動で記録** ― 完全な監査証跡」 |

> これらはすべて、**人間の運用に頼らず、プラットフォームが自動的に実行**しています。
>
> SOC2 Type 2の監査で求められるのは「統制が**継続的に**機能している」ことの証明です。
> HashiCorpのプラットフォームは、その証明を**日々の開発運用の中で自動的に生成**します。

---

## トラブルシューティング

### Sentinel の実行が表示されない場合

- ワークスペースにポリシーセットが紐づいているか確認
- HCP Terraform → Organization Settings → Policy Sets

### Plan が開始されない場合

- ワークスペースの VCS 連携が正しく設定されているか確認
- HCP Terraform → Workspace → Settings → Version Control

### 「想定通りFAILしない」場合

- `terraform/variables.tf` の `enable_encryption` が確実に `false` になっているか確認
- `sentinel/enforce-s3-encryption.sentinel` がポリシーセットに含まれているか確認

---

## クイックコマンドリファレンス

```bash
# STEP 1: 暗号化なしブランチを作成
git checkout main && git checkout -b demo/missing-encryption
sed -i 's/default     = true/default     = false/' terraform/variables.tf
git add -A && git commit -m "feat: add S3 bucket" && git push -u origin demo/missing-encryption

# STEP 2: 暗号化を有効化して修正
sed -i 's/default     = false/default     = true/' terraform/variables.tf
git add -A && git commit -m "fix: enable encryption" && git push

# デモ後のクリーンアップ
git checkout main
git branch -d demo/missing-encryption
git push origin --delete demo/missing-encryption
```

---

## 画面遷移マップ

```
[ターミナル]          [GitHub]               [HCP Terraform]
    |                     |                        |
    |-- git push -------->|                        |
    |                     |-- PR作成 ------------->|
    |                     |                        |-- Plan開始
    |                     |                        |-- Sentinel Check
    |                     |                        |   (STEP1: FAIL)
    |                     |                        |
    |-- 修正コミット ---->|-- PR更新 ------------->|
    |                     |                        |-- Re-Plan
    |                     |                        |-- Sentinel Check
    |                     |                        |   (STEP2: PASS)
    |                     |                        |-- Vault認証
    |                     |                        |-- Apply実行
    |                     |                        |
    |                     |                  [Run詳細画面]
    |                     |                        |
    |                     |              STEP3: 監査証跡確認
    |                     |              - 誰のPRか
    |                     |              - どのポリシーをパスしたか
    |                     |              - どの権限で実行されたか
```
