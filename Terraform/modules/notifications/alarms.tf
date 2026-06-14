# =========================================================
# CloudWatch alarms -> SNS. Node CPU > 80%, RDS free storage < 2GB.
# =========================================================

# Node CPU > 80% (EKS Container Insights metric, per cluster).
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-node-cpu-high"
  alarm_description   = "EKS node CPU utilization is over 80%"
  namespace           = "ContainerInsights"
  metric_name         = "node_cpu_utilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  statistic           = "Average"
  period              = 300 # 5 min
  evaluation_periods  = 2   # breach 2 periods -> avoid flapping

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.cloudnest_sns_topic.arn]
  ok_actions    = [aws_sns_topic.cloudnest_sns_topic.arn]
}

# RDS free storage < 2GB. Only created when an RDS instance id is provided.
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  count = var.rds_instance_id != "" ? 1 : 0

  alarm_name          = "${var.project}-${var.environment}-rds-low-storage"
  alarm_description   = "RDS free storage is below 2GB"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  comparison_operator = "LessThanThreshold"
  threshold           = 2147483648 # 2GB in BYTES
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.cloudnest_sns_topic.arn]
  ok_actions    = [aws_sns_topic.cloudnest_sns_topic.arn]
}

