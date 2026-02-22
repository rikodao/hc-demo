# Vault Dynamic Provider Credentials により AWS 認証情報が自動注入される。
# HCP Terraform が Vault に OIDC で認証し、一時的な IAM 認証情報を取得する。
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Compliance  = "soc2"
    }
  }
}
