# =========================================================
# EXAMPLE IRSA POD ROLE - a pod that can read S3, with NO static keys.
# Pattern: trust (scoped to ONE ServiceAccount) -> role -> permissions.
# =========================================================

locals {
  # Strip "https://" from the issuer URL to build the OIDC condition keys
  oidc_provider = replace(var.oidc_issuer_url, "https://", "")
}

# Step 3: TRUST policy - ONLY this specific ServiceAccount may assume the role
data "aws_iam_policy_document" "s3_reader_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"] # WebIdentity, not plain AssumeRole

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    # The pod's token MUST match this exact ServiceAccount (namespace + name)
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:default:s3-reader-sa"]
    }

    # The token audience must be sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Step 4: the ROLE
resource "aws_iam_role" "s3_reader" {
  name               = "${var.project}-${var.environment}-s3-reader-irsa"
  assume_role_policy = data.aws_iam_policy_document.s3_reader_trust.json
}

# Step 5: WHAT it can do - attach S3 read-only (example permission)
resource "aws_iam_role_policy_attachment" "s3_reader" {
  role       = aws_iam_role.s3_reader.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

