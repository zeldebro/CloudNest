# Provider: region + default_tags (applied to EVERY bootstrap resource automatically)
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Create a KMS key for encrypting CloudNest bootstrap resources
resource "aws_kms_key" "cloudnest_kms_key" {
  description             = "KMS key for CloudNest bootstrap resources"
  deletion_window_in_days = 15
  tags = {
    Name = "${var.project}-${var.environment}-kms-key"
  }
}
# Random 8-char hex suffix (e.g. a1b2c3d4) so the GLOBALLY-unique bucket name
# never collides. Stored in state, so it stays stable across applies.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Create an S3 bucket for storing CloudNest bootstrap resources
resource "aws_s3_bucket" "cloudnest_s3_bucket" {
  bucket = "${var.project}-${var.environment}-bucket-bootstrap-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "${var.project}-s3-bucket"
  }
}

# S3 Versioning enabling
resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.cloudnest_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#Create S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.cloudnest_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudnest_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

#S3 Public access blocking
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.cloudnest_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create daynamodb table for CloudNest bootstrap resources
resource "aws_dynamodb_table" "cloudnest_dynamodb_table" {
  name         = "${var.project}-${var.environment}-dynamodb-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.project}-${var.environment}-dynamodb-table"
  }

}
