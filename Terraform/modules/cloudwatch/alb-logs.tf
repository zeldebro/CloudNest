# =========================================================
# ALB access logs -> dedicated S3 bucket
# AWS only supports ALB access logs to S3 (NOT CloudWatch Logs).
# Enable on the controller-created ALB via the Ingress annotation:
#   alb.ingress.kubernetes.io/load-balancer-attributes:
#     access_logs.s3.enabled=true,access_logs.s3.bucket=<this bucket>
# =========================================================
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "alb_logs" {
  # account id keeps the bucket name globally unique
  bucket = "${var.project}-${var.environment}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project}-${var.environment}-alb-logs"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket                  = aws_s3_bucket.alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Allow the ELB log-delivery service to write access logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowELBLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

