# KMS key for EKS secret envelope encryption (AWS-0039)
resource "aws_kms_key" "eks_secrets" {
  description             = "KMS key for EKS secret encryption (${var.cloudnest_eks_cluster_name})"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  tags = {
    Name = "${var.cloudnest_eks_cluster_name}-secrets"
  }
}

resource "aws_eks_cluster" "cloudnest_eks_cluster" {
  name     = var.cloudnest_eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.cloudenest_eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    # Public access is configurable. CI (GitHub-hosted runners) needs the API
    # reachable; restrict the CIDRs from dev.tfvars to tighten exposure.
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs    = var.public_access_cidrs
  }

  # Envelope-encrypt Kubernetes secrets with the CMK above (AWS-0039)
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }

  # Enable EKS Access Entries (API) alongside the legacy configmap
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.cloudenest_eks_cluster_policy]
}
