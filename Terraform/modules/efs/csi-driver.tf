# =========================================================
# EFS CSI driver - IRSA role + EKS managed addon.
# Trust: scoped to the CSI controller + node ServiceAccounts in kube-system.
# Permissions: the AWS-managed AmazonEFSCSIDriverPolicy.
# Pattern mirrors the alb module (iam.tf).
# =========================================================
data "aws_iam_policy_document" "efs_csi_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # StringLike covers both efs-csi-controller-sa and efs-csi-node-sa
    condition {
      test     = "StringLike"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-*"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "efs_csi" {
  name               = "${var.project}-${var.environment}-efs-csi-irsa"
  assume_role_policy = data.aws_iam_policy_document.efs_csi_trust.json
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  role       = aws_iam_role.efs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
}

# --- EKS managed addon (auto-patched, cleaner than Helm) ---
resource "aws_eks_addon" "efs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = var.csi_driver_addon_version
  service_account_role_arn = aws_iam_role.efs_csi.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_iam_role_policy_attachment.efs_csi]
}

