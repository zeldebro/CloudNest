variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to link the private hosted zone to"
  type        = string
}

variable "zone_name" {
  description = "Private DNS zone name"
  type        = string
  default     = "cloudnest.internal"
}

