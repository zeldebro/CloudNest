# =========================================================
# WAF logging -> dedicated CloudWatch log group
# Shows, per request, which rule ALLOWED/BLOCKED/COUNTED it.
# NOTE: the log group name MUST start with "aws-waf-logs-" (AWS requirement).
# =========================================================
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.project}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name = "${var.project}-${var.environment}-waf-logs"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudnest" {
  resource_arn = aws_wafv2_web_acl.cloudnest.arn
  # WAF expects the log group ARN WITHOUT the trailing ":*"
  log_destination_configs = [trimsuffix(aws_cloudwatch_log_group.waf.arn, ":*")]
}

