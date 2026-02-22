#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# HCP Terraform ワークスペースに Vault Dynamic Provider Credentials の
# 環境変数を設定するスクリプト
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

TFC_ORG="rikodao-org"
TFC_WORKSPACE="soc2-compliance-demo"
TFC_API="https://app.terraform.io/api/v2"
VAULT_ADDR="https://vault-cluster-public-vault-668ba449.d96a1cd4.z1.hashicorp.cloud:8200"

if [ -z "${TFC_TOKEN:-}" ]; then
  echo -e "${YELLOW}TFC_TOKEN が未設定です。TFC User Token を入力してください:${NC}"
  read -rs TFC_TOKEN
  export TFC_TOKEN
fi

echo -e "${BLUE}=== HCP Terraform Vault 連携設定 ===${NC}"
echo ""

# ワークスペース ID を取得
WS_ID=$(curl -s \
  -H "Authorization: Bearer $TFC_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  "${TFC_API}/organizations/${TFC_ORG}/workspaces/${TFC_WORKSPACE}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")

echo -e "${GREEN}Workspace ID:${NC} $WS_ID"

# 環境変数を設定する関数
set_env_var() {
  local key="$1"
  local value="$2"
  local sensitive="${3:-false}"
  local category="${4:-env}"

  # 既存の変数を検索
  local existing
  existing=$(curl -s \
    -H "Authorization: Bearer $TFC_TOKEN" \
    "${TFC_API}/workspaces/${WS_ID}/vars" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for v in data.get('data', []):
    if v['attributes']['key'] == '${key}':
        print(v['id'])
        break
" 2>/dev/null || true)

  if [ -n "$existing" ]; then
    # 既存変数を更新
    curl -s -X PATCH \
      -H "Authorization: Bearer $TFC_TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      "${TFC_API}/workspaces/${WS_ID}/vars/${existing}" \
      -d "{
        \"data\": {
          \"type\": \"vars\",
          \"id\": \"${existing}\",
          \"attributes\": {
            \"key\": \"${key}\",
            \"value\": \"${value}\",
            \"sensitive\": ${sensitive},
            \"category\": \"${category}\"
          }
        }
      }" > /dev/null
    echo -e "  ${GREEN}✓${NC} ${key} (updated)"
  else
    # 新規変数を作成
    curl -s -X POST \
      -H "Authorization: Bearer $TFC_TOKEN" \
      -H "Content-Type: application/vnd.api+json" \
      "${TFC_API}/workspaces/${WS_ID}/vars" \
      -d "{
        \"data\": {
          \"type\": \"vars\",
          \"attributes\": {
            \"key\": \"${key}\",
            \"value\": \"${value}\",
            \"sensitive\": ${sensitive},
            \"category\": \"env\"
          }
        }
      }" > /dev/null
    echo -e "  ${GREEN}✓${NC} ${key} (created)"
  fi
}

# ダミー AWS 変数を削除する関数
delete_env_var() {
  local key="$1"
  local var_id
  var_id=$(curl -s \
    -H "Authorization: Bearer $TFC_TOKEN" \
    "${TFC_API}/workspaces/${WS_ID}/vars" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for v in data.get('data', []):
    if v['attributes']['key'] == '${key}':
        print(v['id'])
        break
" 2>/dev/null || true)

  if [ -n "$var_id" ]; then
    curl -s -X DELETE \
      -H "Authorization: Bearer $TFC_TOKEN" \
      "${TFC_API}/workspaces/${WS_ID}/vars/${var_id}" > /dev/null
    echo -e "  ${RED}✗${NC} ${key} (deleted)"
  fi
}

echo ""
echo -e "${BLUE}[1/3]${NC} ダミー AWS 認証変数を削除..."
delete_env_var "AWS_ACCESS_KEY_ID"
delete_env_var "AWS_SECRET_ACCESS_KEY"
delete_env_var "AWS_DEFAULT_REGION"

echo ""
echo -e "${BLUE}[2/3]${NC} Vault Provider Auth 変数を設定..."
set_env_var "TFC_VAULT_PROVIDER_AUTH" "true"
set_env_var "TFC_VAULT_ADDR" "$VAULT_ADDR"
set_env_var "TFC_VAULT_RUN_ROLE" "tfc-soc2-demo"
set_env_var "TFC_VAULT_NAMESPACE" "admin"

echo ""
echo -e "${BLUE}[3/3]${NC} Vault-backed AWS 認証変数を設定..."
set_env_var "TFC_VAULT_BACKED_AWS_AUTH" "true"
set_env_var "TFC_VAULT_BACKED_AWS_AUTH_TYPE" "iam_user"
set_env_var "TFC_VAULT_BACKED_AWS_RUN_VAULT_ROLE" "terraform-soc2-demo"
set_env_var "TFC_VAULT_BACKED_AWS_MOUNT_PATH" "aws"

echo ""
echo -e "${GREEN}=== 設定完了 ===${NC}"
echo -e "HCP Terraform ワークスペースが Vault 経由で動的 AWS 認証情報を取得する設定になりました。"
