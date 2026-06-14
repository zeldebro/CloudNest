data "aws_caller_identity" "current" {}

# Customer-managed KMS key for the Loki bucket (AWS-0132)
resource "aws_kms_key" "loki" {
  description             = "KMS key for the CloudNest Loki logs bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "loki" {
  name          = "alias/${var.project}/${var.environment}/loki"
  target_key_id = aws_kms_key.loki.id
}

resource "aws_s3_bucket" "cloudnest_loki_s3_bucket" {
  # Bucket names are GLOBALLY unique - suffix with account id
  bucket = "${var.project}-${var.environment}-loki-${data.aws_caller_identity.current.account_id}"
  tags = {
    Name = "${var.project}-${var.environment}-loki-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudnest_loki_s3_bucket_encryption" {
  bucket = aws_s3_bucket.cloudnest_loki_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.loki.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudnest_loki_s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.cloudnest_loki_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudnest_loki_s3_bucket_versioning" {
  bucket = aws_s3_bucket.cloudnest_loki_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Expire old log chunks to control cost
resource "aws_s3_bucket_lifecycle_configuration" "cloudnest_loki_s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.cloudnest_loki_s3_bucket.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    expiration {
      days = var.log_retention_days
    }
  }
}
