# =============================================================================
# SOC2 コンプライアンスデモ - S3 バケット設定
#
# enable_encryption 変数で暗号化の有無を切り替え可能。
# false の場合、Sentinel ポリシー (enforce-s3-encryption) によりブロックされる。
# =============================================================================

# --- 顧客データ用バケット ---

resource "aws_s3_bucket" "data_store" {
  bucket = "${var.project_name}-data-${var.environment}"

  tags = {
    Name       = "${var.project_name}-data-store"
    DataClass  = "confidential"
    Compliance = "soc2-type2"
    AuthMethod = "vault-oidc"
    AuthMethod = "vault-oidc"
  }
}

resource "aws_s3_bucket_versioning" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "data_store" {
  bucket = aws_s3_bucket.data_store.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- データバケットの暗号化設定（条件付き） ---

resource "aws_s3_bucket_server_side_encryption_configuration" "data_store" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.data_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# --- 監査ログ用バケット ---

resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project_name}-access-logs-${var.environment}"

  tags = {
    Name       = "${var.project_name}-access-logs"
    Purpose    = "audit-trail"
    Compliance = "soc2-type2"
    AuthMethod = "vault-oidc"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- データバケットのアクセスログ出力設定 ---

resource "aws_s3_bucket_logging" "data_store" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.data_store.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "s3-access-logs/"
}
