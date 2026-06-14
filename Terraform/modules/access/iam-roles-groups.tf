# =========================================================
# IAM Roles + Groups for EKS access (fully Terraform-managed)
#
# Pattern ("one role, many users"):
#   IAM Group  <-- you add/remove users here (the on/off switch)
#     │ group policy allows sts:AssumeRole
#     ▼
#   IAM Role   <-- mapped once to an EKS access policy (below)
#     ▼
#   EKS Access Entry + Policy Association (admin / edit / view)
#
# Onboarding a user = add them to the group in IAM. No Terraform change.
# =========================================================

data "aws_caller_identity" "current" {}

# 1. One IAM role per access level (e.g. eks-admins / eks-developers / eks-readonly)
resource "aws_iam_role" "team" {
  for_each = var.access_roles

  name = "${var.project}-${var.environment}-${each.key}"

  # Trust: allow IAM principals in THIS account to assume the role.
  # Actual permission to assume is granted by the group policy below,
  # so only group members can assume it.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "sts:AssumeRole"
        Condition = {
          Bool = { "aws:MultiFactorAuthPresent" = "true" }
        }
      }
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# 2. One IAM group per access level - this is where you add users.
resource "aws_iam_group" "team" {
  for_each = var.access_roles

  name = "${var.project}-${var.environment}-${each.key}-group"
}

# 3. Group policy: members are allowed to assume the matching role.
resource "aws_iam_group_policy" "assume_role" {
  for_each = var.access_roles

  name  = "assume-${each.key}"
  group = aws_iam_group.team[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.team[each.key].arn
      }
    ]
  })
}

# 4. Map each auto-created role -> an EKS access entry + policy association.
resource "aws_eks_access_entry" "team" {
  for_each = var.access_roles

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.team[each.key].arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "team" {
  for_each = var.access_roles

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.team[each.key].arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.scope_type
    namespaces = each.value.scope_type == "namespace" ? each.value.namespaces : null
  }

  depends_on = [aws_eks_access_entry.team]
}

