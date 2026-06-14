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

# GitHub repo allowed to assume the CI role, in "org/repo" form
# (e.g. "my-org/CloudNest"). Used in the OIDC trust policy.
variable "github_repo" {
  description = "GitHub repository (org/repo) allowed to assume the GitHub Actions role"
  type        = string
}
