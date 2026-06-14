variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region (passed to the LB controller chart)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the controller manages ALBs in"
  type        = string
}

# --- IRSA wiring (from the irsa module) ---
variable "oidc_provider_arn" {
  description = "IAM OIDC provider ARN (module.irsa.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// (module.irsa.oidc_provider_url)"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for aws-load-balancer-controller"
  type        = string
  default     = "1.8.1"
}

