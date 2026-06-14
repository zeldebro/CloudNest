output "gitlab_secret_arn" {
  description = "ARN of the GitLab credentials secret (grant pods secretsmanager:GetSecretValue on this)"
  value       = aws_secretsmanager_secret.gitlab.arn
}

output "gitlab_secret_name" {
  description = "Name of the GitLab credentials secret"
  value       = aws_secretsmanager_secret.gitlab.name
}

output "gitlab_kms_key_arn" {
  description = "KMS key ARN encrypting the GitLab secret (grant pods kms:Decrypt on this)"
  value       = aws_kms_key.gitlab.arn
}

