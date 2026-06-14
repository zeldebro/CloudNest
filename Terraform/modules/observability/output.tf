# =========================================================
# Observability module outputs
# =========================================================

output "monitoring_namespace" {
  description = "Namespace where the monitoring stack runs"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_release_name" {
  description = "Helm release name of kube-prometheus-stack"
  value       = helm_release.cloudnest_prometheus.name
}

# --- Grafana admin credentials (password lives in Secrets Manager) ---
output "grafana_admin_secret_name" {
  description = "Secrets Manager secret holding the Grafana admin password"
  value       = aws_secretsmanager_secret.cloudenest_grafana_admin.name
}

output "grafana_admin_secret_arn" {
  description = "ARN of the Grafana admin Secrets Manager secret"
  value       = aws_secretsmanager_secret.cloudenest_grafana_admin.arn
}

output "grafana_port_forward_command" {
  description = "Command to reach Grafana locally"
  value       = "kubectl port-forward -n ${kubernetes_namespace.monitoring.metadata[0].name} svc/${helm_release.cloudnest_prometheus.name}-grafana 3000:80"
}

# --- Loki ---
output "loki_bucket_name" {
  description = "S3 bucket storing Loki log chunks"
  value       = aws_s3_bucket.cloudnest_loki_s3_bucket.id
}

output "loki_irsa_role_arn" {
  description = "IRSA role ARN used by Loki to access S3"
  value       = aws_iam_role.loki.arn
}

