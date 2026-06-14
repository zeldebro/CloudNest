resource "aws_cloudwatch_log_group" "cloudnest_vpc_flow_log" {
  name              = "/aws/vpc/${var.project}-${var.environment}-flow-logs"
  retention_in_days = 30
  tags = {
    Name = "${var.project}-${var.environment}-vpc-flow-log-group"
  }
}