variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name Karpenter provisions nodes for"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS API server endpoint (Karpenter needs it to bootstrap nodes)"
  type        = string
}

# --- IRSA wiring (from the irsa module) ---
variable "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider (from module.irsa.oidc_provider_arn)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL without https:// (from module.irsa.oidc_provider_url)"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  # Must support the cluster's K8s version (older releases panic on a mismatch)
  # and be >=1.1.1 so it has no dead public.ecr.aws/bitnami/kubectl migration hook.
  default = "1.12.0"
}

variable "karpenter_namespace" {
  description = "Namespace where Karpenter runs"
  type        = string
  default     = "karpenter"
}

# --- Reused node role from the EKS module (DRY - no duplicate role) ---
variable "node_role_arn" {
  description = "ARN of the node IAM role (reused from the EKS module)"
  type        = string
}

variable "node_role_name" {
  description = "NAME of the node IAM role (reused from the EKS module) for the instance profile"
  type        = string
}

# --- EC2NodeClass blueprints (map - one per AMI profile) ---
variable "ec2_node_classes" {
  description = "Map of EC2NodeClass blueprints. Key = name (e.g. default, gpu)."
  type = map(object({
    ami_alias = string
    disk_size = string
  }))
  default = {
    default = { ami_alias = "al2023@latest", disk_size = "50Gi" }
    gpu     = { ami_alias = "al2023@latest", disk_size = "100Gi" }
  }
}

variable "general_nodepool" {
  description = "CPU NodePool settings (capacity types, instance families, limits)"
  type = object({
    capacity_types      = list(string)
    instance_categories = list(string)
    cpu_limit           = string
    memory_limit        = string
  })
  default = {
    capacity_types      = ["spot", "on-demand"]
    instance_categories = ["c", "m", "r"]
    cpu_limit           = "1000"
    memory_limit        = "1000Gi"
  }
}

variable "gpu_nodepool" {
  description = "GPU NodePool settings (capacity types, instance families, GPU limit)"
  type = object({
    capacity_types    = list(string)
    instance_families = list(string)
    gpu_limit         = string
  })
  default = {
    capacity_types    = ["spot", "on-demand"]
    instance_families = ["g5", "g4dn"]
    gpu_limit         = "8"
  }
}


