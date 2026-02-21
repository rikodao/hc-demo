terraform {
  required_version = ">= 1.5.0"

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
