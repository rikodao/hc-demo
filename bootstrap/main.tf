terraform {
  required_version = ">= 1.5.0"

  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.100"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.61"
    }
  }
}

provider "hcp" {
  project_id = var.hcp_project_id
}

provider "tfe" {
  hostname = "app.terraform.io"
}

# --- HCP 組織情報の取得 ---

data "hcp_organization" "current" {}

# --- HCP Terraform リソース ---

data "tfe_organization" "demo" {
  name = data.hcp_organization.current.name
}

# GitHub VCS 連携（OAuth クライアント）
resource "tfe_oauth_client" "github" {
  organization     = data.tfe_organization.demo.name
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  service_provider = "github"
  oauth_token      = var.github_token
}

# デモ用ワークスペース
resource "tfe_workspace" "soc2_demo" {
  name         = "soc2-compliance-demo"
  organization = data.tfe_organization.demo.name
  description  = "SOC2 Compliance Demo - S3 with Sentinel + Vault"

  auto_apply        = false
  queue_all_runs    = false
  working_directory = "terraform"

  vcs_repo {
    identifier     = "rikodao/hc-demo"
    branch         = "main"
    oauth_token_id = tfe_oauth_client.github.oauth_token_id
  }
}

# Sentinel ポリシーセット（VCS 連携で sentinel/ ディレクトリから自動同期）
resource "tfe_policy_set" "sentinel" {
  name         = "soc2-s3-policies"
  description  = "SOC2 compliance policies for S3 bucket security"
  organization = data.tfe_organization.demo.name
  kind         = "sentinel"

  workspace_ids = [tfe_workspace.soc2_demo.id]

  vcs_repo {
    identifier         = "rikodao/hc-demo"
    branch             = "main"
    oauth_token_id     = tfe_oauth_client.github.oauth_token_id
    ingress_submodules = false
  }

  policies_path = "sentinel"
}

variable "hcp_project_id" {
  type        = string
  description = "HCP Project ID"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token"
}

output "workspace_id" {
  value = tfe_workspace.soc2_demo.id
}

output "workspace_url" {
  value = tfe_workspace.soc2_demo.html_url
}

output "policy_set_id" {
  value = tfe_policy_set.sentinel.id
}
