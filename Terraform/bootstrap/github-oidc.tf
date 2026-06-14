# =========================================================
# GitHub Actions OIDC -> AWS (keyless CI/CD auth)
#
# Registers GitHub as a trusted OIDC identity provider, then creates
# a role GitHub Actions can assume (no static AWS keys).
#
# ⚠️ This is the GITHUB OIDC provider (token.actions.githubusercontent.com)
#    - completely separate from the EKS OIDC provider used for IRSA.
# =========================================================

# 1. Register GitHub's OIDC provider in this AWS account
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub's cert thumbprints (AWS now validates via its CA store, but the
  # resource still requires at least one).
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fca",
  ]
}

# 2. Trust policy: only YOUR repo (optionally a specific branch/env) may assume
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scope to your repo. Examples:
    #   repo:my-org/CloudNest:*                      (any branch/PR)
    #   repo:my-org/CloudNest:ref:refs/heads/main    (main only)
    #   repo:my-org/CloudNest:environment:dev        (dev environment only)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

# 3. The role GitHub Actions assumes to run Terraform
resource "aws_iam_role" "github_actions" {
  name               = "${var.project}-${var.environment}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
}

# 4. Permissions: Terraform manages the whole stack, so this is broad.
#    Tighten to least-privilege for production.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

