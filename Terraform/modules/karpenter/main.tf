# =========================================================
# Karpenter node instance profile.
# REUSES the EKS node role (var.node_role_name) - only the profile is Karpenter-owned.
# =========================================================
resource "aws_iam_instance_profile" "node" {
  name = "${var.project}-${var.environment}-karpenter-node"
  role = var.node_role_name
}

# =========================================================
# Karpenter install via Helm.
# Values come from ONE source: the module's template, fed by Terraform
# variables (which come from dev.tfvars). path.module = GitHub-safe relative path.
# =========================================================
resource "helm_release" "cloudnest_karpenter" {
  name             = "karpenter"
  namespace        = var.karpenter_namespace
  create_namespace = true

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  values = [
    # Single source of truth: addon values template inside this module.
    # Env-specific values (cluster_name, etc.) arrive via Terraform variables.
    templatefile("${path.module}/values/karpenter.yaml.tpl", {
      controller_role_arn = aws_iam_role.controller.arn
      cluster_name        = var.cluster_name
      cluster_endpoint    = var.cluster_endpoint
      interruption_queue  = aws_sqs_queue.interruption.name
    })
  ]

  # IAM + queue must exist before the controller starts
  depends_on = [
    aws_iam_role_policy.controller,
    aws_iam_instance_profile.node,
    aws_sqs_queue.interruption,
  ]
}