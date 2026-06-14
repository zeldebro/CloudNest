variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}
variable "alert_email" {
  description = "Email address that receives notifications (SNS email subscription)"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly cost budget limit in USD (e.g. \"100\")"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS DBInstanceIdentifier to watch for free storage (empty disables the alarm)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "EKS cluster name (used as an alarm dimension)"
  type        = string
}
