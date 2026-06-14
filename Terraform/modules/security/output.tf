# =========================================================
# Expose SG IDs so the EKS module can attach them
# cluster_sg -> attached to EKS control plane
# node_sg    -> attached to worker node group
# =========================================================
output "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.cloudnest_eks_cluster_sg.id
}

output "node_security_group_id" {
  description = "Security group ID for the EKS worker nodes"
  value       = aws_security_group.cloudnest_eks_node_sg.id
}

output "rds_security_group_id" {
  description = "Security group ID for the RDS instance (attach in the rds module)"
  value       = aws_security_group.cloudnest_rds_sg.id
}
