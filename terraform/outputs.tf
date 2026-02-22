output "data_bucket_arn" {
  description = "顧客データ用 S3 バケットの ARN"
  value       = aws_s3_bucket.data_store.arn
}

output "data_bucket_name" {
  description = "顧客データ用 S3 バケットの名前"
  value       = aws_s3_bucket.data_store.id
}

output "encryption_enabled" {
  description = "サーバーサイド暗号化が有効かどうか"
  value       = var.enable_encryption
}

output "logs_bucket_arn" {
  description = "監査ログ用 S3 バケットの ARN"
  value       = aws_s3_bucket.access_logs.arn
}
