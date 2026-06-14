output "web_acl_arn" {
  description = "ARN of the WAF Web ACL (use in the Ingress annotation wafv2-acl-arn)"
  value       = aws_wafv2_web_acl.cloudnest.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudnest.id
}

output "waf_log_group_name" {
  description = "CloudWatch log group holding WAF allow/block logs"
  value       = aws_cloudwatch_log_group.waf.name
}
