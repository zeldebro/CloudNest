variable "project" {
  description = "Project name"
  type        = string
  default     = "cloudnest"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# --- Repo policy principals (least privilege) ---
variable "node_role_arn" {
  description = "IAM role ARN that may PULL images (the EKS node role)"
  type        = string
}

variable "runner_role_arn" {
  description = "IAM role ARN that may PUSH images (the CI/CD runner role)"
  type        = string
}
