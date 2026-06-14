variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "cloudnest_admin"
}

variable "db_name" {
  description = "Initial database name created inside the instance"
  type        = string
  default     = "cloudnest"
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

# --- Networking (cross-module wiring) ---
variable "private_subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "Security group IDs to attach to the DB (created in the security module)"
  type        = list(string)
}

# --- Engine / sizing (low-cost defaults) ---
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "RDS instance class (db.t4g.micro = cheapest current-gen)"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB (20 = minimum / lowest cost)"
  type        = number
  default     = 20
}
