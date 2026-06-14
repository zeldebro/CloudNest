# =========================================================
# Interruption handling: SQS queue + EventBridge rules.
# AWS sends Spot interruption / node termination events here;
# Karpenter reads them and drains nodes gracefully (2-min warning).
# =========================================================

resource "aws_sqs_queue" "interruption" {
  name                      = "${var.project}-${var.environment}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}

# Allow EventBridge to send messages to the queue
data "aws_iam_policy_document" "interruption_queue_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.interruption.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.url
  policy    = data.aws_iam_policy_document.interruption_queue_policy.json
}

# EventBridge rules that feed the queue
locals {
  interruption_events = {
    spot_interruption = { source = "aws.ec2", detail-type = "EC2 Spot Instance Interruption Warning" }
    rebalance         = { source = "aws.ec2", detail-type = "EC2 Instance Rebalance Recommendation" }
    state_change      = { source = "aws.ec2", detail-type = "EC2 Instance State-change Notification" }
    scheduled_change  = { source = "aws.health", detail-type = "AWS Health Event" }
  }
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = local.interruption_events
  name     = "${var.project}-${var.environment}-karpenter-${each.key}"
  event_pattern = jsonencode({
    source        = [each.value.source]
    "detail-type" = [each.value["detail-type"]]
  })
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = local.interruption_events
  rule     = aws_cloudwatch_event_rule.interruption[each.key].name
  arn      = aws_sqs_queue.interruption.arn
}

