#!/bin/bash
set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} STEP 3: 完全な監査証跡の確認${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}シナリオ:${NC} 実行結果を監査の視点で確認します"
echo ""

echo -e "${BLUE}[確認ポイント 1]${NC} 誰のPRか（GitHub連携）"
echo -e "  → HCP Terraform UI → Runs → 最新の実行 → 'Triggered via' セクション"
echo ""

echo -e "${BLUE}[確認ポイント 2]${NC} どのポリシーをパスしたか"
echo -e "  → HCP Terraform UI → Runs → Policy Check セクション"
echo -e "  → enforce-s3-encryption: ✓ Passed"
echo -e "  → require-public-access-block: ✓ Passed"
echo ""

echo -e "${BLUE}[確認ポイント 3]${NC} どの一時的なAWS権限をVaultから借りたか"
echo -e "  → HCP Terraform UI → Runs → Plan/Apply ログ"
echo -e "  → Vault Audit Log で認証履歴を確認"
echo ""

echo -e "${YELLOW}メッセージ:${NC}"
echo -e "  「監査対応時にCloudTrailを数時間かけて検索する必要はありません。"
echo -e "   この1画面がそのまま『証跡レポート』になります。」"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} 確認先URL${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  HCP Terraform: ${BLUE}https://app.terraform.io${NC}"
echo -e "  GitHub PR:     ${BLUE}https://github.com/rikodao/hc-demo/pulls${NC}"
echo -e "  HCP Portal:    ${BLUE}https://portal.cloud.hashicorp.com${NC}"
echo ""
