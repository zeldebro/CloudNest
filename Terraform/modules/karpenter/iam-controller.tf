
# =========================================================
# ROLE 1: Karpenter CONTROLLER role (IRSA - the "hand" that creates nodes)
# Trust scoped to the karpenter ServiceAccount in the karpenter namespace.
# =========================================================

# TRUST: only the karpenter ServiceAccount may assume this role
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
      values   = ["system:serviceaccount:${var.karpenter_namespace}:karpenter"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "controller" {
  name               = "${var.project}-${var.environment}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.controller_trust.json
}

# PERMISSIONS: what the Karpenter controller can do (launch/terminate EC2, etc.)
data "aws_iam_policy_document" "controller_permissions" {
  statement {
    sid    = "AllowEC2Provisioning"
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AllowPricing"
    effect    = "Allow"
    actions   = ["pricing:GetProducts", "ssm:GetParameter"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowInterruptionQueue"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = [aws_sqs_queue.interruption.arn]
  }

  # Karpenter must pass the NODE role to the instances it launches
  statement {
    sid       = "AllowPassNodeRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [var.node_role_arn]
  }
}

resource "aws_iam_role_policy" "controller" {
  name   = "${var.project}-${var.environment}-karpenter-controller-policy"
  role   = aws_iam_role.controller.id
  policy = data.aws_iam_policy_document.controller_permissions.json
}

