# Root (dev) variable declarations.
# VALUES for these are set ONCE in dev.tfvars and passed down to modules.

variable "project" {
  description = "Project name"
  type        = string
  default     = "cloudnest"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr_block" {
  description = "Map of AZ to CIDR for public subnets"
  type        = map(string)
}

variable "private_subnet_cidr_block" {
  description = "Map of AZ to CIDR for private subnets"
  type        = map(string)
}


variable "eks_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "cluster_endpoint_public_access" {
  description = "Expose the EKS API publicly (CI on GitHub-hosted runners needs true)."
  type        = bool
  default     = true
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API. Restrict to your IP(s) to reduce exposure."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ALL node groups live here as data. Add/change a group = edit dev.tfvars ONLY.
variable "node_groups" {
  description = "Map of EKS managed node groups. Key = node group name."
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    ami_type       = string
    disk_size      = number
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}

# --- Karpenter NodePool config (tunable from dev.tfvars) ---
variable "ec2_node_classes" {
  description = "Map of EC2NodeClass blueprints (default + gpu)"
  type = map(object({
    ami_alias = string
    disk_size = string
  }))
}

# --- EKS addons config ---
variable "addon_versions" {
  description = "Versions for core EKS addons (null = EKS default)"
  type = object({
    vpc_cni    = optional(string)
    coredns    = optional(string)
    kube_proxy = optional(string)
  })
  default = {}
}

variable "vpc_cni_config" {
  description = "VPC CNI settings (prefix delegation, warm target, pod ENI)"
  type = object({
    enable_prefix_delegation = bool
    warm_prefix_target       = number
    enable_pod_eni           = bool
  })
}

# --- ECR repo policy: the CI/CD runner role allowed to PUSH images ---
# Leave empty to auto-derive the GitHub Actions OIDC role ARN
# (arn:aws:iam::<account>:role/<project>-<env>-github-actions) in main.tf.
variable "runner_role_arn" {
  description = "IAM role ARN of the CI/CD runner that may push images to ECR (empty = derive GitHub Actions role)"
  type        = string
  default     = ""
}

# --- Notifications: email that receives alerts ---
variable "alert_email" {
  description = "Email address that receives notifications (SNS email subscription)"
  type        = string
}

variable "monthly_budget_limit" {
  description = "Monthly cost budget limit in USD"
  type        = string
}


variable "general_nodepool" {
  description = "CPU NodePool settings"
  type = object({
    capacity_types      = list(string)
    instance_categories = list(string)
    cpu_limit           = string
    memory_limit        = string
  })
}

variable "gpu_nodepool" {
  description = "GPU NodePool settings"
  type = object({
    capacity_types    = list(string)
    instance_families = list(string)
    gpu_limit         = string
  })
}

# --- EKS user access (Access Entries) ---
variable "eks_access_entries" {
  description = "IAM principal -> EKS access policy mappings (who can use the cluster)"
  type = map(object({
    principal_arn = string
    policy_arn    = string
    scope_type    = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
  default = {}
}

# --- EKS access roles+groups (auto-created by Terraform) ---
# Terraform creates an IAM role + group per level and maps it to EKS.
# Onboard a user = add them to the generated IAM group. No Terraform change.
variable "eks_access_roles" {
  description = "IAM roles + groups to auto-create and map to EKS access policies"
  type = map(object({
    policy_arn = string
    scope_type = optional(string, "cluster")
    namespaces = optional(list(string), [])
  }))
  default = {}
}

# --- WAF IP allowlist ---
# Public IP CIDRs that bypass WAF block rules (use your PUBLIC IP from `curl ifconfig.me`).
# Note: home/ISP IPs are dynamic - update + re-apply if it changes.
variable "waf_allowed_ips" {
  description = "Trusted public IP CIDRs that bypass WAF block rules"
  type        = list(string)
  default     = []
}

# --- GitLab credentials (stored in Secrets Manager) ---
variable "gitlab_url" {
  description = "GitLab instance URL"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_username" {
  description = "GitLab username for CI/CD"
  type        = string
  default     = ""
}

# --- Observability (kube-prometheus-stack) ---
variable "enable_observability" {
  description = "Feature flag: when true, deploy Prometheus + Alertmanager + Grafana."
  type        = bool
  default     = false
}

# --- Karpenter ---
variable "karpenter_version" {
  description = "Karpenter Helm chart version (>=1.1.1 avoids the dead bitnami/kubectl migration hook)."
  type        = string
  default     = "1.1.1"
}

variable "monitoring_namespace" {
  description = "Namespace for the monitoring stack."
  type        = string
  default     = "monitoring"
}

variable "storage_class" {
  description = "StorageClass for monitoring persistence (reuse the EFS efs-sc)."
  type        = string
  default     = "efs-sc"
}

# Observability tunables (all overridable from dev.tfvars)
variable "prometheus_storage_size" {
  description = "Prometheus TSDB volume size."
  type        = string
  default     = "50Gi"
}

variable "grafana_storage_size" {
  description = "Grafana volume size."
  type        = string
  default     = "10Gi"
}

variable "alertmanager_storage_size" {
  description = "Alertmanager volume size."
  type        = string
  default     = "5Gi"
}

variable "loki_storage_size" {
  description = "Loki single-binary WAL/cache volume size."
  type        = string
  default     = "10Gi"
}

variable "kube_prometheus_chart_version" {
  description = "Pinned kube-prometheus-stack chart version."
  type        = string
  default     = "65.5.1"
}

variable "loki_chart_version" {
  description = "Pinned grafana/loki chart version."
  type        = string
  default     = "6.6.4"
}

variable "promtail_chart_version" {
  description = "Pinned grafana/promtail chart version."
  type        = string
  default     = "6.16.4"
}

variable "log_retention_days" {
  description = "Days before Loki log chunks expire from S3."
  type        = number
  default     = 30
}

variable "slo_target" {
  description = "Availability SLO target as a fraction (0.995 = 99.5%)."
  type        = number
  default     = 0.995
}

# --- EFS (RWX shared storage for PVCs) ---
variable "enable_efs" {
  description = "Feature flag: when true, create the EFS filesystem, CSI driver and efs-sc StorageClass. When false, nothing EFS-related is created."
  type        = bool
  default     = false
}

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


