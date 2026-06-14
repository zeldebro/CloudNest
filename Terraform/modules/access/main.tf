# =========================================================
# EKS Access Entries (modern, API-based access control)
# Maps an IAM principal (role/user) -> an EKS access policy.
# Requires the cluster authentication_mode to include "API".
# =========================================================

# 1. Register each principal as an access entry
resource "aws_eks_access_entry" "this" {
  for_each = var.access_entries

  cluster_name  = var.cluster_name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
}

# 2. Attach an access policy (permission level) to each principal
resource "aws_eks_access_policy_association" "this" {
  for_each = var.access_entries

  cluster_name  = var.cluster_name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.scope_type
    namespaces = each.value.scope_type == "namespace" ? each.value.namespaces : null
  }

  # Ensure the entry exists before associating a policy
  depends_on = [aws_eks_access_entry.this]
}

