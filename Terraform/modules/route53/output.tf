output "zone_id" {
  description = "ID of the private hosted zone (used by ExternalDNS / records)"
  value       = aws_route53_zone.private.zone_id
}

output "zone_name" {
  description = "Name of the private hosted zone"
  value       = aws_route53_zone.private.name
}

output "dns_query_log_group_name" {
  description = "CloudWatch log group holding Route53 DNS query logs"
  value       = aws_cloudwatch_log_group.dns_queries.name
}
