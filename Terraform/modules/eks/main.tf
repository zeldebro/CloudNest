resource "aws_eks_cluster" "cloudnest_eks_cluster" {
  name     = var.cloudnest_eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.cloudenest_eks_cluster_role.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable EKS Access Entries (API) alongside the legacy configmap
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [aws_iam_role_policy_attachment.cloudenest_eks_cluster_policy]
}
