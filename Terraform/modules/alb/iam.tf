# =========================================================
# AWS Load Balancer Controller - IRSA role
# Trust: ONLY the kube-system/aws-load-balancer-controller ServiceAccount.
# Permissions: the official AWS LB Controller IAM policy (json file).
# Verify the json matches your chart version:
#   https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json
# =========================================================
data "aws_iam_policy_document" "controller_trust" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "controller" {
  name        = "${var.project}-${var.environment}-alb-controller"
  description = "Permissions for the AWS Load Balancer Controller"
  policy      = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role" "controller" {
  name               = "${var.project}-${var.environment}-alb-controller-irsa"
  assume_role_policy = data.aws_iam_policy_document.controller_trust.json
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}

