# =========================================================
# Route53 DNS query logging -> dedicated CloudWatch log group
# Uses Route53 RESOLVER query logging (works for private zones), which logs
# all DNS queries made from within the associated VPC.
# =========================================================
resource "aws_cloudwatch_log_group" "dns_queries" {
  name              = "/aws/route53/${var.project}-${var.environment}-dns-queries"
  retention_in_days = 30

  tags = {
    Name = "${var.project}-${var.environment}-dns-query-logs"
  }
}

resource "aws_route53_resolver_query_log_config" "this" {
  name            = "${var.project}-${var.environment}-dns-query-log"
  destination_arn = aws_cloudwatch_log_group.dns_queries.arn

  tags = {
    Name = "${var.project}-${var.environment}-dns-query-log"
  }
}

# Associate the logging config with the VPC so its DNS queries are captured
resource "aws_route53_resolver_query_log_config_association" "this" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.this.id
  resource_id                  = var.vpc_id
}

