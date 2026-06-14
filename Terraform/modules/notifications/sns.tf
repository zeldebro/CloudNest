# =========================================================
# SNS topic (STANDARD - required for email + CloudWatch + Budgets).
# Provider requirements live in versions.tf.
# =========================================================
resource "aws_sns_topic" "cloudnest_sns_topic" {
  name              = "${var.project}-${var.environment}-notifications-topic"
  kms_master_key_id = aws_kms_key.cloudnest_sns_key.id
}
resource "aws_sns_topic_policy" "cloiudnest_sns_policy" {
  arn = aws_sns_topic.cloudnest_sns_topic.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAndBudgetsPublish"
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "budgets.amazonaws.com"
          ]
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cloudnest_sns_topic.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "cloudnest_sns_subscription" {
  topic_arn = aws_sns_topic.cloudnest_sns_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}