variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}



variable "cloudnest_eks_cluster_name" {
  description = "EKS cluster name - used for the kubernetes.io/cluster discovery tag"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where the EKS control plane ENIs and nodes live"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS control plane"
  type        = string
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server is reachable publicly (CI on GitHub-hosted runners needs this true)."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Tighten from dev.tfvars."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =========================================================
# ALL node groups defined as ONE map of objects.
# To add/change a node group in future: edit tfvars ONLY.
# The module loops over this map with for_each -> no module changes needed.
# =========================================================
variable "node_groups" {
  description = "Map of EKS managed node groups. Key = node group name."
  type = map(object({
    instance_types = list(string)
    capacity_type  = string # ON_DEMAND or SPOT
    ami_type       = string # e.g. AL2023_x86_64_STANDARD, AL2023_x86_64_NVIDIA
    disk_size      = number
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE
    }))
  }))
}