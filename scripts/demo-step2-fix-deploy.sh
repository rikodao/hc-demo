#!/bin/bash
set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} STEP 2: 動的認証によるデプロイ (Vault)${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}シナリオ:${NC} 暗号化設定を修正し、Vault経由の動的認証でデプロイします"
echo ""

cd "$(dirname "$0")/.."

echo -e "${BLUE}[デモ操作]${NC} 暗号化を有効化して修正コミット..."

git checkout demo/no-encryption 2>/dev/null || git checkout feature/add-s3-data-store 2>/dev/null

# Enable encryption
sed -i 's/default     = false/default     = true/' terraform/variables.tf

git add -A
git commit -m "fix: enable S3 server-side encryption for SOC2 compliance" 2>/dev/null || true
git push 2>/dev/null

echo ""
echo -e "${GREEN}[ポイント]${NC} HCP TerraformがVaultに対して一時的なAWS権限を要求します"
echo -e "${GREEN}[ポイント]${NC} 実行ログで「AWSアクセスキーを一切使っていない（OIDC連携）」ことを確認"
echo ""
echo -e "${YELLOW}メッセージ:${NC}"
echo -e "  「GitHub ActionsやHCP Terraformに『永続的な鍵』は保存されていません。"
echo -e "   実行の瞬間にVaultから払い出された、数分間だけ有効な一時的な権限で"
echo -e "   動作しています。鍵の漏洩リスクは実質ゼロです。」"
echo ""
echo -e "${BLUE}確認: HCP Terraform UI → Runs → 実行ログを表示${NC}"
echo ""
