terraform {
  required_version = ">= 1.5.0"

  cloud {
    # Set via TF_CLOUD_ORGANIZATION environment variable
    # organization = "your-org-name"

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
