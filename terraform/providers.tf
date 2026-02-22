# デモ環境では実 AWS アカウントを使用しないため、認証チェックをスキップ。
# 本番環境では skip_* オプションを削除し、Vault 動的認証を使用すること。
provider "aws" {
  region = var.aws_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Compliance  = "soc2"
    }
  }
}
