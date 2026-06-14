project     = "cloudnest"
region      = "us-east-1"
environment = "dev"
# =========================================================
# VPC - the ONLY place you edit to add/change a group.
# =========================================================
vpc_cidr_block = "10.0.0.0/16"
public_subnet_cidr_block = {
  "us-east-1a" = "10.0.0.0/24"
  "us-east-1b" = "10.0.1.0/24"
  "us-east-1c" = "10.0.2.0/24"
}
private_subnet_cidr_block = {
  "us-east-1a" = "10.0.16.0/20"
  "us-east-1b" = "10.0.32.0/20"
  "us-east-1c" = "10.0.48.0/20"
}

# Cluster name is DERIVED in locals (project-env-eks-cluster), not set here.
eks_version = "1.35"

# =========================================================
# NODE GROUPS - the ONLY place you edit to add/change a group.
# Want a 3rd group? Add another key. Bump max_size? Change it here.
# =========================================================
node_groups = {
  # SYSTEM baseline: hosts Karpenter controller + CoreDNS + system pods.
  # On-Demand + 2 nodes across AZs = stable HA home (Karpenter can't host itself).
  system = {
    instance_types = ["m6i.large", "m5.large"]
    capacity_type  = "ON_DEMAND" # system pods must NOT risk Spot reclaim
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = 50
    desired_size   = 2 # one per AZ for HA
    min_size       = 2 # never below - Karpenter always needs a home
    max_size       = 3 # small headroom
    labels = {
      workload = "system"
    }
    taints = []
  }
  # NOTE: GPU + general workloads now handled by Karpenter NodePools
  # (see modules/karpenter/manifests). No managed GPU node group needed.
}

# =========================================================
# KARPENTER NodePools - tune Spot/limits/families here (no module edits).
# =========================================================
# EC2NodeClass blueprints: "default" for CPU, "gpu" for GPU (bigger disk).
ec2_node_classes = {
  default = {
    ami_alias = "al2023@latest" # or "bottlerocket@latest"
    disk_size = "50Gi"
  }
  gpu = {
    ami_alias = "al2023@latest" # AL2023 auto-selects the GPU-accelerated AMI for GPU instances
    disk_size = "100Gi"
  }
}

general_nodepool = {
  capacity_types      = ["spot", "on-demand"] # Spot-first, On-Demand fallback
  instance_categories = ["c", "m", "r"]
  cpu_limit           = "1000"
  memory_limit        = "1000Gi"
}

gpu_nodepool = {
  capacity_types    = ["spot", "on-demand"] # change to ["on-demand"] for strict SLA
  instance_families = ["g5", "g4dn"]
  gpu_limit         = "8"
}

# =========================================================
# EKS ADDONS - VPC CNI prefix delegation /28 + warm target.
# =========================================================
vpc_cni_config = {
  enable_prefix_delegation = true  # /28 blocks = ~110 pods/node
  warm_prefix_target       = 1     # keep 1 spare /28 ready for fast startup
  enable_pod_eni           = false # set true for per-pod security groups
}

# Pin addon versions for reproducibility (or leave {} for EKS defaults)
addon_versions = {
  vpc_cni    = null
  coredns    = null
  kube_proxy = null
}

# CI/CD runner role allowed to PUSH images to ECR.
# Leave unset to auto-derive the GitHub Actions OIDC role
# (cloudnest-dev-github-actions) created by the bootstrap stack.
# Override only if a different role pushes images:
# runner_role_arn = "arn:aws:iam::<account-id>:role/<role-name>"

# =========================================================
# NOTIFICATIONS - email that receives alerts (confirm via the email link)
# =========================================================
alert_email = "raghub.learn@gmail.com"

# Monthly cost budget (USD) - alerts at 80% actual + 100% forecasted
monthly_budget_limit = "100"

# =========================================================
# WAF IP ALLOWLIST - your PUBLIC IP that bypasses WAF block rules.
# Get it with: curl ifconfig.me   (home IPs are dynamic - re-apply if it changes)
# =========================================================
waf_allowed_ips = ["223.233.87.209/32"]

# =========================================================
# GITLAB CREDENTIALS -> stored in Secrets Manager (KMS-encrypted).
# Put the username + URL here. NEVER put the password here.
# Pass the password via environment variable before apply:
#   export TF_VAR_gitlab_password='your-password-or-token'
# =========================================================
gitlab_url      = "https://gitlab.com"
gitlab_username = "admin"

# =========================================================
# EFS - shared ReadWriteMany (RWX) storage for PVCs.
# Creates EFS + per-AZ mount targets + NFS SG + CSI driver + efs-sc StorageClass.
# =========================================================
enable_efs = true

# Optional tuning (defaults shown). throughput_mode "elastic" = pay-per-use.
# efs_config = {
#   performance_mode                = "generalPurpose"
#   throughput_mode                 = "elastic"
#   transition_to_ia                = "AFTER_30_DAYS"
#   transition_to_primary_on_access = true
# }

# =========================================================
# OBSERVABILITY - kube-prometheus-stack (Prometheus + Alertmanager + Grafana).
# Persistence reuses the EFS efs-sc StorageClass (needs enable_efs = true).
# Every tunable below is read from THIS file - no module edits needed.
# =========================================================
enable_observability = true
monitoring_namespace = "monitoring"
storage_class        = "efs-sc"

# Prometheus / chart versions
prometheus_storage_size       = "50Gi"
grafana_storage_size          = "10Gi"
alertmanager_storage_size     = "5Gi"
loki_storage_size             = "10Gi"
kube_prometheus_chart_version = "65.5.1" # verify: helm search repo prometheus-community/kube-prometheus-stack --versions

# Loki + Promtail (log aggregation)
loki_chart_version     = "6.6.4"  # verify: helm search repo grafana/loki --versions
promtail_chart_version = "6.16.4" # verify: helm search repo grafana/promtail --versions
log_retention_days     = 30

# SLO target (0.995 = 99.5% availability, 30-day window)
slo_target = 0.995

# =========================================================
# EKS ACCESS ROLES + GROUPS - Terraform CREATES these for you.
# For each level below, Terraform makes:
#   - an IAM role  (cloudnest-dev-<key>)        <- users assume this
#   - an IAM group (cloudnest-dev-<key>-group)  <- add users HERE
#   - the EKS access mapping (admin/edit/view)
# Onboard a user = add them to the IAM group. No terraform apply needed.
# =========================================================
eks_access_roles = {
  # 🔴 Full cluster admin (SRE / platform team)
  eks-admins = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
    scope_type = "cluster"
  }
  # 🟡 Developers: edit/deploy, limited to the demo namespace
  eks-developers = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
    scope_type = "namespace"
    namespaces = ["demo"]
  }
  # 🟢 Read-only across the whole cluster (auditors / viewers)
  eks-readonly = {
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    scope_type = "cluster"
  }
}

