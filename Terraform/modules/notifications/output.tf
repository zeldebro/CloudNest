# =========================================================
# Outputs - ONLY what leaves the module (consumed by apps / IAM / root).
# =========================================================

# SNS topic - other alert sources publish here; root displays it.
output "sns_topic_arn" {
  description = "ARN of the SNS notifications topic"
  value       = aws_sns_topic.cloudnest_sns_topic.arn
}

# Main queue - the app sends messages here.
output "sqs_main_queue_url" {
  description = "URL of the main SQS queue (apps publish messages here)"
  value       = aws_sqs_queue.cloudnest_sqs_main.url
}

output "sqs_main_queue_arn" {
  description = "ARN of the main SQS queue (used in IAM policies)"
  value       = aws_sqs_queue.cloudnest_sqs_main.arn
}

# DLQ - useful for monitoring dashboards.
output "sqs_dlq_arn" {
  description = "ARN of the dead-letter queue"
  value       = aws_sqs_queue.cloudnest_sqs_dlq.arn
}

# KMS key - if another module encrypts with the same key.
output "kms_key_arn" {
  description = "ARN of the KMS key used for notifications encryption"
  value       = aws_kms_key.cloudnest_sns_key.arn
}


