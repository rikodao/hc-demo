variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "nextpay-soc2-demo"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

# false の場合、Sentinel ポリシー (enforce-s3-encryption) によりブロックされる
variable "enable_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = false
}
