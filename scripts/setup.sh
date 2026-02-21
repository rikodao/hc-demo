#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} SOC2 Compliance Demo - Setup Script${NC}"
echo -e "${BLUE} HCP Terraform + Sentinel + Vault${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check required env vars
check_env() {
  local var_name=$1
  if [ -z "${!var_name:-}" ]; then
    echo -e "${RED}ERROR: ${var_name} is not set${NC}"
    echo "  export ${var_name}=\"your-value\""
    return 1
  fi
  echo -e "${GREEN}  ✓ ${var_name} is set${NC}"
}

echo -e "${YELLOW}[1/5] Checking environment variables...${NC}"
MISSING=0
check_env "HCP_CLIENT_ID" || MISSING=1
check_env "HCP_CLIENT_SECRET" || MISSING=1
check_env "TF_VAR_github_token" || MISSING=1
check_env "TF_VAR_hcp_project_id" || MISSING=1

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo -e "${RED}Missing environment variables. Please set them and re-run.${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}[2/5] Authenticating with HCP...${NC}"
HCP_TOKEN=$(curl -s --request POST \
  --url https://auth.idp.hashicorp.com/oauth2/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=${HCP_CLIENT_ID}" \
  --data-urlencode "client_secret=${HCP_CLIENT_SECRET}" \
  --data-urlencode 'audience=https://api.hashicorp.cloud' | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

export TFE_TOKEN="$HCP_TOKEN"
echo -e "${GREEN}  ✓ HCP authentication successful${NC}"

echo ""
echo -e "${YELLOW}[3/5] Checking HCP Terraform organization...${NC}"
ORG_INFO=$(curl -s --header "Authorization: Bearer $HCP_TOKEN" \
  "https://api.hashicorp.cloud/resource-manager/2019-12-10/organizations" | \
  python3 -c "import sys,json; orgs=json.load(sys.stdin)['organizations']; print(json.dumps(orgs[0]))")

ORG_NAME=$(echo "$ORG_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
TFC_SYNCED=$(echo "$ORG_INFO" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tfc_synced', False))")

echo -e "  Organization: ${BLUE}${ORG_NAME}${NC}"
echo -e "  TFC Synced: ${TFC_SYNCED}"

if [ "$TFC_SYNCED" = "False" ] || [ "$TFC_SYNCED" = "false" ]; then
  echo ""
  echo -e "${RED}================================================================${NC}"
  echo -e "${RED} HCP Terraform organization is not yet enabled!${NC}"
  echo -e "${RED}================================================================${NC}"
  echo ""
  echo -e "Please complete the following steps:"
  echo -e "  1. Go to ${BLUE}https://portal.cloud.hashicorp.com${NC}"
  echo -e "  2. Navigate to ${YELLOW}Services → Terraform${NC}"
  echo -e "  3. Click ${YELLOW}'Create a Terraform organization'${NC}"
  echo -e "  4. Use organization name: ${GREEN}${ORG_NAME}${NC}"
  echo -e "  5. Re-run this script"
  echo ""
  exit 1
fi

echo -e "${GREEN}  ✓ HCP Terraform is enabled${NC}"

echo ""
echo -e "${YELLOW}[4/5] Setting up Terraform workspace...${NC}"
cd "$(dirname "$0")/../bootstrap"
terraform init -upgrade
terraform apply -auto-approve

WORKSPACE_URL=$(terraform output -raw workspace_url 2>/dev/null || echo "N/A")

echo -e "${GREEN}  ✓ Workspace created: ${WORKSPACE_URL}${NC}"

echo ""
echo -e "${YELLOW}[5/5] Verifying setup...${NC}"
WORKSPACE_ID=$(terraform output -raw workspace_id 2>/dev/null || echo "N/A")
POLICY_SET_ID=$(terraform output -raw policy_set_id 2>/dev/null || echo "N/A")

echo -e "${GREEN}  ✓ Workspace ID: ${WORKSPACE_ID}${NC}"
echo -e "${GREEN}  ✓ Policy Set ID: ${POLICY_SET_ID}${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Next steps for the demo:"
echo -e "  1. Go to the PR: ${BLUE}https://github.com/rikodao/hc-demo/pull/1${NC}"
echo -e "  2. Check HCP Terraform: ${BLUE}${WORKSPACE_URL}${NC}"
echo -e "  3. Sentinel will block the PR (no encryption)"
echo -e "  4. The fix commit (enable_encryption=true) is already pushed"
echo ""
