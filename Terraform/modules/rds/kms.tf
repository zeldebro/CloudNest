data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudnest_rds_kms_key" {
  description             = "KMS key for encrypting RDS instances in CloudNest"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "cloudnest_rds_kms_key_alias" {
  target_key_id = aws_kms_key.cloudnest_rds_kms_key.id
  name          = "alias/cloudnest/rds"
}
resource "aws_kms_key_policy" "cloudnest_rds_kms_key_policy" {
  key_id = aws_kms_key.cloudnest_rds_kms_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    # ONE Statement array with ONE statement: admin only
    Statement = [
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = ["kms:*"]
        Resource = "*"
      }
    ]
  })
}