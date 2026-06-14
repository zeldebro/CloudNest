output "access_entry_principals" {
  description = "IAM principals that were granted cluster access"
  value       = [for e in aws_eks_access_entry.this : e.principal_arn]
}

# Map of level label -> generated IAM role ARN (what users assume).
output "team_role_arns" {
  description = "Auto-created IAM role ARNs per access level"
  value       = { for k, r in aws_iam_role.team : k => r.arn }
}

# Map of level label -> generated IAM group name (where you add users).
output "team_group_names" {
  description = "Auto-created IAM group names per access level"
  value       = { for k, g in aws_iam_group.team : k => g.name }
}

