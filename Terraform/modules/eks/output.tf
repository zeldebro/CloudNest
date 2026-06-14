# =========================================================
# EKS module outputs - consumed by kubectl, IRSA, and other modules
# =========================================================

# --- Cluster identity (for `aws eks update-kubeconfig`) ---
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cloudnest_eks_cluster.name
}

output "cluster_endpoint" {
  description = "API server endpoint URL"
  value       = aws_eks_cluster.cloudnest_eks_cluster.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64-encoded CA cert for TLS trust to the API server"
  value       = aws_eks_cluster.cloudnest_eks_cluster.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version running on the control plane"
  value       = aws_eks_cluster.cloudnest_eks_cluster.version
}

# --- OIDC: THE key piece that unlocks IRSA ---
output "oidc_issuer_url" {
  description = "OIDC issuer URL of the cluster (used to create the IAM OIDC provider for IRSA)"
  value       = aws_eks_cluster.cloudnest_eks_cluster.identity[0].oidc[0].issuer
}

# --- The cluster security group AWS auto-creates (different from ours) ---
output "cluster_primary_security_group_id" {
  description = "The SG automatically created by EKS for the control plane"
  value       = aws_eks_cluster.cloudnest_eks_cluster.vpc_config[0].cluster_security_group_id
}

# --- Node groups (loops over the for_each map) ---
output "node_group_names" {
  description = "Names of all managed node groups"
  value       = [for ng in aws_eks_node_group.this : ng.node_group_name]
}

output "node_role_arn" {
  description = "IAM role ARN used by the worker nodes"
  value       = aws_iam_role.cloudenest_eks_node_role.arn
}

output "node_role_name" {
  description = "IAM role NAME used by the worker nodes (reused by Karpenter instance profile)"
  value       = aws_iam_role.cloudenest_eks_node_role.name
}

