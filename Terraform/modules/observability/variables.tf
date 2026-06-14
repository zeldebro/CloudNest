variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "monitoring_namespace" {
  description = "The namespace to deploy the monitoring stack into."
  type        = string
}

variable "storage_class" {
  description = "StorageClass for Prometheus/Grafana/Alertmanager persistence (reuse efs-sc)."
  type        = string
  default     = "efs-sc"
}

variable "prometheus_storage_size" {
  description = "Persistent volume size for the Prometheus TSDB."
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Persistent volume size for Grafana."
  type        = string
  default     = "10Gi"
}

variable "alertmanager_storage_size" {
  description = "Persistent volume size for Alertmanager."
  type        = string
  default     = "5Gi"
}

variable "loki_storage_size" {
  description = "Persistent volume size for the Loki single-binary WAL/cache."
  type        = string
  default     = "10Gi"
}

variable "chart_version" {
  description = "Pinned kube-prometheus-stack chart version."
  type        = string
  default     = "65.5.1"
}

# --- Loki / Promtail (CNP-017) ---
variable "region" {
  description = "AWS region (Loki S3 storage)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN (from module.irsa) for the Loki IRSA role."
  type        = string
}

variable "oidc_provider_url" {
  description = "IAM OIDC provider URL without https:// (from module.irsa)."
  type        = string
}

variable "loki_chart_version" {
  description = "Pinned grafana/loki chart version."
  type        = string
  default     = "6.6.4"
}

variable "promtail_chart_version" {
  description = "Pinned grafana/promtail chart version."
  type        = string
  default     = "6.16.4"
}

variable "log_retention_days" {
  description = "Days before Loki log chunks expire from S3."
  type        = number
  default     = 30
}

# --- SLO (CNP-018) ---
variable "slo_target" {
  description = "Availability SLO target as a fraction (0.995 = 99.5%)."
  type        = number
  default     = 0.995
}
