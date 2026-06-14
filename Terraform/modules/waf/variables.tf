variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "rate_limit" {
  description = "Max requests per IP per 5-minute window before blocking"
  type        = number
  default     = 2000
}

variable "allowed_ips" {
  description = "Trusted IP CIDRs that bypass WAF block rules (e.g. [\"1.2.3.4/32\"]). Empty = no allowlist rule."
  type        = list(string)
  default     = []
}
