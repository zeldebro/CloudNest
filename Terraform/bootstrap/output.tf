# Output variables for CloudNest bootstrap resources
output "bootstrap_bucket_name" {
  description = "The name of the S3 bucket created for CloudNest bootstrap resources"
  value       = aws_s3_bucket.cloudnest_s3_bucket.id
}
# Output the ARN of the KMS key created for CloudNest bootstrap resources
output "bootstrap_kms_key_arn" {
  description = "The ARN of the KMS key created for CloudNest bootstrap resources"
  value       = aws_kms_key.cloudnest_kms_key.arn
}
# Output the name of the DynamoDB table created for CloudNest bootstrap resources
output "bootstrap_dynamodb_table_name" {
  description = "The name of the DynamoDB table created for CloudNest bootstrap resources"
  value       = aws_dynamodb_table.cloudnest_dynamodb_table.id
}

# GitHub Actions role ARN -> put this in the GitHub Secret AWS_ROLE_ARN
output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC (set as GitHub Secret AWS_ROLE_ARN)"
  value       = aws_iam_role.github_actions.arn
}
