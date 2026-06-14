variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will be created"
  type        = string
}

variable "cloudnest_eks_cluster_name" {
  description = "EKS cluster name - used for the kubernetes.io/cluster discovery tag"
  type        = string
}
