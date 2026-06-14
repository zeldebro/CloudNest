# =========================================================
# SQS: a MAIN queue + a DLQ (dead-letter queue).
# Main queue redrives failed messages to the DLQ after 3 tries.
# Provider requirements live in versions.tf (not here).
# =========================================================

# 1. DLQ - the "failure parking lot". Plain queue, NO redrive_policy.
resource "aws_sqs_queue" "cloudnest_sqs_dlq" {
  name                      = "${var.project}-${var.environment}-sqs-dlq"
  message_retention_seconds = 1209600 # 14 days - keep failures long enough to investigate
  kms_master_key_id         = aws_kms_key.cloudnest_sns_key.id
}

# 2. MAIN queue - has the redrive_policy pointing to the DLQ.
resource "aws_sqs_queue" "cloudnest_sqs_main" {
  name                       = "${var.project}-${var.environment}-sqs-main"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 345600 # 4 days
  max_message_size           = 262144
  delay_seconds              = 0
  receive_wait_time_seconds  = 10 # long polling
  kms_master_key_id          = aws_kms_key.cloudnest_sns_key.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.cloudnest_sqs_dlq.arn
    maxReceiveCount     = 3 # after 3 failed receives -> DLQ
  })
}

# 3. The DLQ's "guest list": only the MAIN queue may redrive into it.
resource "aws_sqs_queue_redrive_allow_policy" "cloudnest_sqs_redrive_allow_policy" {
  queue_url = aws_sqs_queue.cloudnest_sqs_dlq.id
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.cloudnest_sqs_main.arn]
  })
}