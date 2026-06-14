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