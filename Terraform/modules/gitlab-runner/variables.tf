variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "gitlab_url" {
  description = "GitLab instance URL (e.g. https://gitlab.com)"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_username" {
  description = "GitLab username for CI/CD"
  type        = string
}


# --- Helm / runner config ---
variable "namespace" {
  description = "Kubernetes namespace for the GitLab Runner"
  type        = string
  default     = "gitlab-runner"
}

variable "chart_version" {
  description = "gitlab-runner Helm chart version"
  type        = string
  default     = "0.66.0"
}


variable "concurrent_jobs" {
  description = "Number of CI jobs the runner executes concurrently"
  type        = number
  default     = 4
}

# --- IRSA wiring (from the irsa + eks modules) ---
variable "cluster_name" {
  description = "EKS cluster name (for the runner's access entry)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN (module.irsa.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// (module.irsa.oidc_provider_url)"
  type        = string
}

variable "service_account_name" {
  description = "ServiceAccount name for the runner (annotated with the IRSA role)"
  type        = string
  default     = "gitlab-runner"
}

