variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

# --- Network wiring (from the vpc module) ---
variable "private_subnet_ids" {
  description = "Private subnet IDs - ONE EFS mount target is created per subnet/AZ"
  type        = list(string)
}

# --- Security wiring (from the security module) ---
variable "node_security_group_id" {
  description = "EKS node security group ID allowed to reach EFS over NFS 2049"
  type        = string
}

# The SG EKS auto-creates and attaches to managed-node-group instances (and pods
# via the CNI). This is the SG that nodes ACTUALLY use, so EFS must allow NFS from
# it - otherwise mounts time out (DeadlineExceeded) even though the custom node SG
# is allowed. Pass module.eks.cluster_primary_security_group_id.
variable "cluster_primary_security_group_id" {
  description = "EKS-managed cluster security group ID (attached to nodes) allowed to reach EFS over NFS 2049"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EFS security group is created"
  type        = string
}

# --- Cluster + IRSA wiring (from the eks + irsa modules) ---
variable "cluster_name" {
  description = "EKS cluster name the EFS CSI driver addon attaches to"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (from module.irsa.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// (from module.irsa.oidc_provider_url)"
  type        = string
}

# --- EFS tuning ---
variable "efs_config" {
  description = "EFS filesystem settings (performance, throughput, lifecycle)"
  type = object({
    performance_mode                = string
    throughput_mode                 = string
    transition_to_ia                = string
    transition_to_primary_on_access = bool
  })
  default = {
    performance_mode                = "generalPurpose"
    throughput_mode                 = "elastic"
    transition_to_ia                = "AFTER_30_DAYS"
    transition_to_primary_on_access = true
  }
}

variable "csi_driver_addon_version" {
  description = "Version of the aws-efs-csi-driver EKS addon. null = EKS default."
  type        = string
  default     = null
}

variable "storage_class_name" {
  description = "Name of the dynamically-provisioned RWX StorageClass"
  type        = string
  default     = "efs-sc"
}

variable "set_default_storage_class" {
  description = "When true, annotate efs-sc as the cluster default StorageClass"
  type        = bool
  default     = false
}

