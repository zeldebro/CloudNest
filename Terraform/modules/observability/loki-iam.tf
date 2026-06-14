# =========================================================
# Loki IRSA role - lets the Loki pod read/write its S3 bucket with NO static keys.
# Trust scoped to the loki-sa ServiceAccount in the monitoring namespace.
# (Promtail does NOT need this - it ships logs to Loki over HTTP, not S3.)
# =========================================================
data "aws_iam_policy_document" "loki_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.monitoring_namespace}:loki-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "loki" {
  name               = "${var.project}-${var.environment}-loki-irsa"
  assume_role_policy = data.aws_iam_policy_document.loki_trust.json
}

# S3 read/write limited to the Loki bucket
data "aws_iam_policy_document" "loki_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.cloudnest_loki_s3_bucket.arn,
      "${aws_s3_bucket.cloudnest_loki_s3_bucket.arn}/*"
    ]
  }

  # Needed to read/write objects encrypted with the bucket's CMK
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.loki.arn]
  }
}

resource "aws_iam_policy" "loki_s3" {
  name   = "${var.project}-${var.environment}-loki-s3"
  policy = data.aws_iam_policy_document.loki_s3.json
}

resource "aws_iam_role_policy_attachment" "loki_s3" {
  role       = aws_iam_role.loki.name
  policy_arn = aws_iam_policy.loki_s3.arn
}


