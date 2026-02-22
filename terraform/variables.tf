variable "aws_region" {
  description = "AWS リソースをデプロイするリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "リソース名に使用するプロジェクト名"
  type        = string
  default     = "nextpay-soc2-demo"
}

variable "environment" {
  description = "デプロイ環境（production / staging 等）"
  type        = string
  default     = "production"
}

variable "enable_encryption" {
  description = "S3 バケットの暗号化を有効にする（false の場合 Sentinel がブロック）"
  type        = bool
  default     = true
}
