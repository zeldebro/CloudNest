variable "cluster_name" {
  description = "EKS cluster name to grant access on"
  type        = string
}

variable "project" {
  description = "Project name (used to name IAM roles/groups)"
  type        = string
  default     = "cloudnest"
}

variable "environment" {
  description = "Environment name (used to name IAM roles/groups)"
  type        = string
  default     = "dev"
}

# Auto-create an IAM role + group per access level (the "one role, many users" pattern).
# Key = level label (e.g. "eks-admins"). Add users to the generated group in IAM.
#   policy_arn: which EKS access policy the role gets (admin/edit/view)
#   scope_type: "cluster" or "namespace"
#   namespaces: required only when scope_type = "namespace"
variable "access_roles" {
  description = "IAM roles + groups to auto-create and map to EKS access policies"
  type = map(object({
    policy_arn = string
    scope_type = optional(string, "cluster")
    namespaces = optional(list(string), [])
  }))
  default = {}
}

# Map of access entries. Key = a friendly label (e.g. "platform-admins").
# Each maps an IAM principal (role/user ARN) to an EKS access policy.
#   policy_arn examples:
#     arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
#     arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy
#     arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy
#     arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy
#   scope_type: "cluster" (whole cluster) or "namespace" (scoped)
#   namespaces: required only when scope_type = "namespace"
variable "access_entries" {
  description = "IAM principal -> EKS access policy mappings"
  type = map(object({
    principal_arn = string
    policy_arn    = string
    scope_type    = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
  default = {}
}

