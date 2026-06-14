# Fetch the current AWS account ID (used in the root ARN below)
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cloudnest_sns_key" {
  description             = "KMS key for encrypting SNS messages in CloudNest"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_key_policy" "cloudnest_sns_key_policy" {
  key_id = aws_kms_key.cloudnest_sns_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    # ONE Statement array with TWO statements: admin + service usage
    Statement = [
      {
        Sid    = "Allow administration of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = ["kms:*"]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch and Budgets to use the key for SNS encryption"
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "budgets.amazonaws.com"
          ]
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}