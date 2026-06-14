output "repository_url" {
  description = "ECR repository URL (used by CI to push, and in pod image refs)"
  value       = aws_ecr_repository.cloudnest_ecr_repo.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.cloudnest_ecr_repo.arn
}

output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.cloudnest_ecr_repo.name
}

