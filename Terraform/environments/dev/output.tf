# =========================================================
# Root (dev) outputs - shown after `terraform apply`.
# These re-expose child module outputs at the top level.
# =========================================================

# --- VPC ---
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# --- EKS cluster ---
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version"
  value       = module.eks.cluster_version
}

# --- OIDC (needed for IRSA) ---
output "oidc_issuer_url" {
  description = "OIDC issuer URL - foundation for IRSA"
  value       = module.eks.oidc_issuer_url
}

# --- Node groups ---
output "node_group_names" {
  description = "Names of all managed node groups (cpu, gpu)"
  value       = module.eks.node_group_names
}

# --- Handy: the command to connect kubectl ---
output "kubeconfig_command" {
  description = "Run this to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

# --- Observability (only when enable_observability = true) ---
output "monitoring_namespace" {
  description = "Namespace of the monitoring stack (null if disabled)"
  value       = var.enable_observability ? module.observability[0].monitoring_namespace : null
}

output "grafana_admin_secret_name" {
  description = "Secrets Manager secret with the Grafana admin password (null if disabled)"
  value       = var.enable_observability ? module.observability[0].grafana_admin_secret_name : null
}

output "grafana_port_forward_command" {
  description = "Command to open Grafana locally (null if disabled)"
  value       = var.enable_observability ? module.observability[0].grafana_port_forward_command : null
}

output "loki_bucket_name" {
  description = "S3 bucket storing Loki logs (null if disabled)"
  value       = var.enable_observability ? module.observability[0].loki_bucket_name : null
}

