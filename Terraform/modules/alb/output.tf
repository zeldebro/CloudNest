output "controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller ServiceAccount"
  value       = aws_iam_role.controller.arn
}

output "release_name" {
  description = "Helm release name of the AWS Load Balancer Controller"
  value       = helm_release.controller.name
}

