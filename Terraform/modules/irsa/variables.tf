variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# The OIDC issuer URL is OUTPUT BY the cluster - we receive it, never build it.
variable "oidc_issuer_url" {
  description = "OIDC issuer URL from the EKS cluster (module.eks.oidc_issuer_url)"
  type        = string
}