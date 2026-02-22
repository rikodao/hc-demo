#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Vault セットアップスクリプト
#
# 以下を設定する:
#   1. AWS Secrets Engine の動的認証ロール
#   2. JWT Auth Method（HCP Terraform OIDC 信頼関係）
#   3. Vault ポリシー（HCP Terraform 用）
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

VAULT_ADDR="https://vault-cluster-public-vault-668ba449.d96a1cd4.z1.hashicorp.cloud:8200"
TFC_ORG="rikodao-org"
TFC_WORKSPACE="soc2-compliance-demo"

echo -e "${BLUE}=== Vault Setup for SOC2 Demo ===${NC}"
echo ""

# --- Vault トークンの確認 ---
if [ -z "${VAULT_TOKEN:-}" ]; then
  echo -e "${YELLOW}VAULT_TOKEN が未設定です。Admin Token を入力してください:${NC}"
  read -rs VAULT_TOKEN
  export VAULT_TOKEN
fi

export VAULT_ADDR
echo -e "${GREEN}Vault:${NC} $VAULT_ADDR"
echo ""

# --- Step 1: AWS Secrets Engine のロール設定 ---
# (AWS Secrets Engine 自体は UI で有効化・root credential 設定済み前提)
echo -e "${BLUE}[Step 1]${NC} AWS Secrets Engine のロール設定..."

vault write aws/roles/terraform-soc2-demo \
  credential_type=iam_user \
  policy_document=-<<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

echo -e "${GREEN}  ✓ ロール terraform-soc2-demo を作成${NC}"

# --- Step 2: HCP Terraform 用 Vault ポリシー作成 ---
echo -e "${BLUE}[Step 2]${NC} Vault ポリシー作成..."

vault policy write tfc-soc2-demo -<<'HCL'
# HCP Terraform が AWS 動的認証情報を取得するためのポリシー
path "aws/creds/terraform-soc2-demo" {
  capabilities = ["read"]
}
HCL

echo -e "${GREEN}  ✓ ポリシー tfc-soc2-demo を作成${NC}"

# --- Step 3: JWT Auth Method 設定（HCP Terraform OIDC） ---
echo -e "${BLUE}[Step 3]${NC} JWT Auth Method 設定（HCP Terraform OIDC trust）..."

vault auth enable -path=tfc jwt 2>/dev/null || echo "  (jwt auth already enabled)"

vault write auth/tfc/config \
  oidc_discovery_url="https://app.terraform.io" \
  bound_issuer="https://app.terraform.io"

echo -e "${GREEN}  ✓ JWT Auth Method を設定${NC}"

# --- Step 4: JWT Auth ロール設定 ---
echo -e "${BLUE}[Step 4]${NC} JWT Auth ロール設定..."

vault write auth/tfc/role/tfc-soc2-demo \
  role_type="jwt" \
  bound_audiences="vault.workload.identity" \
  bound_claims_type="glob" \
  bound_claims="{\"sub\":\"organization:${TFC_ORG}:workspace:${TFC_WORKSPACE}:run_phase:*\"}" \
  user_claim="terraform_full_workspace" \
  token_policies="tfc-soc2-demo" \
  token_ttl="20m" \
  token_max_ttl="30m"

echo -e "${GREEN}  ✓ ロール tfc-soc2-demo を作成${NC}"

echo ""
echo -e "${GREEN}=== Vault セットアップ完了 ===${NC}"
echo ""
echo -e "以下の情報を HCP Terraform ワークスペースの Environment Variables に設定してください:"
echo ""
echo -e "  ${YELLOW}TFC_VAULT_PROVIDER_AUTH${NC} = true"
echo -e "  ${YELLOW}TFC_VAULT_ADDR${NC}          = ${VAULT_ADDR}"
echo -e "  ${YELLOW}TFC_VAULT_RUN_ROLE${NC}      = tfc-soc2-demo"
echo -e "  ${YELLOW}TFC_VAULT_NAMESPACE${NC}     = admin"
echo ""
echo -e "  ${YELLOW}TFC_VAULT_BACKED_AWS_AUTH${NC}           = true"
echo -e "  ${YELLOW}TFC_VAULT_BACKED_AWS_AUTH_TYPE${NC}      = iam_user"
echo -e "  ${YELLOW}TFC_VAULT_BACKED_AWS_RUN_VAULT_ROLE${NC} = terraform-soc2-demo"
echo -e "  ${YELLOW}TFC_VAULT_BACKED_AWS_MOUNT_PATH${NC}     = aws"
echo ""
echo -e "  以前設定した ${RED}AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY のダミー値は削除${NC} してください。"
