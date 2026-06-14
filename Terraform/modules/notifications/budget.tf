# =========================================================
# AWS Budget: alerts at 80% ACTUAL + 100% FORECASTED spend -> SNS.
# =========================================================
resource "aws_budgets_budget" "cloudnest_budget" {
  name         = "${var.project}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.monthly_budget_limit # e.g. "100"
  limit_unit   = "USD"

  # Alert when ACTUAL spend crosses 80%
  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "ACTUAL"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.cloudnest_sns_topic.arn]
  }

  # Alert when FORECASTED spend crosses 100%
  notification {
    comparison_operator       = "GREATER_THAN"
    notification_type         = "FORECASTED"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    subscriber_sns_topic_arns = [aws_sns_topic.cloudnest_sns_topic.arn]
  }
}
