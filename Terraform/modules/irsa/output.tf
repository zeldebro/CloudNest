# =========================================================
# IRSA module outputs
# =========================================================

# The OIDC provider ARN - reused by EVERY future pod role (Karpenter, CNI, app...)
output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (trust anchor for all IRSA roles)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# The OIDC provider URL (without https://) - used to build trust conditions
output "oidc_provider_url" {
  description = "OIDC provider URL without the https:// prefix"
  value       = replace(var.oidc_issuer_url, "https://", "")
}

# Example pod role ARN - annotate this on the s3-reader-sa ServiceAccount
output "s3_reader_role_arn" {
  description = "ARN to put in the ServiceAccount annotation eks.amazonaws.com/role-arn"
  value       = aws_iam_role.s3_reader.arn
}

