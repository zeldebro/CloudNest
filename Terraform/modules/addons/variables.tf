variable "cluster_name" {
  description = "EKS cluster name the addons attach to"
  type        = string
}

# --- Addon versions (pin for reproducibility; null = EKS default) ---
variable "addon_versions" {
  description = "Versions for core EKS addons. null = let EKS pick the default."
  type = object({
    vpc_cni    = optional(string)
    coredns    = optional(string)
    kube_proxy = optional(string)
  })
  default = {}
}

# --- VPC CNI tuning (prefix delegation + warm targets) ---
variable "vpc_cni_config" {
  description = "VPC CNI production settings"
  type = object({
    enable_prefix_delegation = bool
    warm_prefix_target       = number
    enable_pod_eni           = bool
  })
  default = {
    enable_prefix_delegation = true
    warm_prefix_target       = 1
    enable_pod_eni           = false
  }
}

