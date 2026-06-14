output "log_group_arn" {
  description = "ARN of the VPC flow log CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudnest_vpc_flow_log.arn
}
output "log_group_name" {
  description = "Name of the VPC flow log CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudnest_vpc_flow_log.name
}
output "flow_log_role_arn" {
  description = "ARN of the IAM role for VPC flow logs"
  value       = aws_iam_role.vpc_flow_log_role.arn
}
output "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs (use in the Ingress annotation)"
  value       = aws_s3_bucket.alb_logs.bucket
}
