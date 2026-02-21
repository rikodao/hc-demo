#!/bin/bash
set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}========================================${NC}"
echo -e "${RED} STEP 1: 予防的統制の証明 (Sentinel)${NC}"
echo -e "${RED}========================================${NC}"
echo ""
echo -e "${YELLOW}シナリオ:${NC} エンジニアが誤ってS3暗号化設定を忘れたケースを再現します"
echo ""

cd "$(dirname "$0")/.."

echo -e "${BLUE}[デモ操作]${NC} 暗号化なしのブランチを作成..."
git checkout main 2>/dev/null
git pull origin main 2>/dev/null

git checkout -b demo/no-encryption 2>/dev/null || git checkout demo/no-encryption 2>/dev/null

# Set encryption to false
sed -i 's/default     = true/default     = false/' terraform/variables.tf

git add -A
git commit -m "feat: add S3 bucket for customer data (encryption pending)" 2>/dev/null || true
git push -u origin demo/no-encryption 2>/dev/null

echo ""
echo -e "${RED}[ポイント]${NC} GitHubでPRを作成すると、HCP Terraformが自動的にPlanを実行します"
echo -e "${RED}[ポイント]${NC} Sentinelポリシー 'enforce-s3-encryption' が違反を検知し、デプロイをブロックします"
echo ""
echo -e "${YELLOW}メッセージ:${NC}"
echo -e "  「人間がレビューで見逃しても、プラットフォームが物理的に違反を阻止します。"
echo -e "   これがSOC2で求められる『継続的な統制』の実装です。」"
echo ""
echo -e "${BLUE}PR URL: https://github.com/rikodao/hc-demo/pull/new/demo/no-encryption${NC}"
echo ""
