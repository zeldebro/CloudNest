# =========================================================
# GitLab Runner job pods - IRSA role (keyless AWS access)
#
# Trust: any ServiceAccount in the gitlab-runner namespace (manager + jobs).
# Permissions:
#   - ECR  : build & push/pull images
#   - Secrets Manager + KMS : read the GitLab credentials secret
#   - EKS  : deploy to the cluster (via an access entry below)
# =========================================================


# --- Trust policy: OIDC federation for SAs in the runner namespace ---
data "aws_iam_policy_document" "runner_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # StringLike + "*" so both the runner manager SA and dynamic job SAs match
    condition {
      test     = "StringLike"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "runner" {
  name               = "${var.project}-${var.environment}-gitlab-runner-irsa"
  assume_role_policy = data.aws_iam_policy_document.runner_trust.json
}

# --- Permissions: ECR push/pull + read the GitLab secret ---
data "aws_iam_policy_document" "runner_permissions" {
  # ECR auth token is account-wide (must be "*")
  statement {
    sid       = "ECRAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Push & pull images
  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = ["*"] # scope to specific repo ARNs to tighten
  }

  # Read the GitLab credentials secret
  statement {
    sid       = "ReadGitlabSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.gitlab.arn]
  }

  # Decrypt the secret with its KMS key
  statement {
    sid       = "DecryptGitlabSecret"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.gitlab.arn]
  }
}

resource "aws_iam_role_policy" "runner" {
  name   = "${var.project}-${var.environment}-gitlab-runner-permissions"
  role   = aws_iam_role.runner.id
  policy = data.aws_iam_policy_document.runner_permissions.json
}

# --- Let job pods deploy to the EKS cluster (kubectl/helm) ---
resource "aws_eks_access_entry" "runner" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.runner.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "runner" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.runner.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.runner]
}

