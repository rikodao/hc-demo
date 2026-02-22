output "data_bucket_arn" {
  description = "ARN of the data store S3 bucket"
  value       = aws_s3_bucket.data_store.arn
}

output "data_bucket_name" {
  description = "Name of the data store S3 bucket"
  value       = aws_s3_bucket.data_store.id
}

output "encryption_enabled" {
  description = "Whether server-side encryption is configured"
  value       = var.enable_encryption
}

output "logs_bucket_arn" {
  description = "ARN of the access logs S3 bucket"
  value       = aws_s3_bucket.access_logs.arn
}

