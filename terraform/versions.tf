terraform {
  required_version = ">= 1.5.0"

  # HCP Terraform（旧 Terraform Cloud）でステート管理・Plan 実行
  cloud {
    organization = "rikodao-org"

    workspaces {
      name = "soc2-compliance-demo"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
