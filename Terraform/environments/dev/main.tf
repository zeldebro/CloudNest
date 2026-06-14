# Root module for the DEV environment.
# This is where child modules are CALLED and WIRED together.

# Derived values (tfvars can't interpolate, so we build them here).
locals {
  # Consistent cluster name: cloudnest-dev-eks-cluster
  cluster_name = "${var.project}-${var.environment}-eks-cluster"

  # CI/CD runner that pushes images to ECR.
  # Defaults to the GitHub Actions OIDC role created in bootstrap
  # (cloudnest-dev-github-actions). Account ID is resolved dynamically,
  # so no hardcoded ARN is needed. Override via var.runner_role_arn if desired.
  runner_role_arn = var.runner_role_arn != "" ? var.runner_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-${var.environment}-github-actions"

  # The IAM identity Terraform runs as in CI = the GitHub Actions OIDC role.
  # It MUST have cluster-admin so the helm/kubectl/kubernetes providers can
  # authenticate to the EKS API (otherwise: 401 "server asked for credentials").
  # Granted via an EKS Access Entry below (an AWS-API call - needs NO cluster
  # auth itself), so it self-bootstraps even on a cluster created by someone else.
  terraform_runner_access = {
    terraform-runner = {
      principal_arn = local.runner_role_arn
      policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      scope_type    = "cluster"
      namespaces    = []
    }
  }
}

# Current AWS account (used to build the runner role ARN without hardcoding it)
data "aws_caller_identity" "current" {}

# Provider: region + default_tags (applied to EVERY resource automatically)
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Helm provider: authenticates to the EKS cluster so helm_release (Karpenter) works.
# Uses `aws eks get-token` via exec - no static kubeconfig needed.
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# kubectl provider: applies Karpenter NodePool/EC2NodeClass manifests.
provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# kubernetes provider: used by the observability module (namespace + secrets).
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# CloudWatch module: creates the flow-log log group + IAM role
module "cloudwatch" {
  source      = "../../modules/cloudwatch"
  project     = var.project
  region      = var.region
  environment = var.environment
}

# VPC module: network + flow logs.
# Note how cloudwatch OUTPUTS are wired into VPC INPUTS (module.cloudwatch.<output>).
module "vpc" {
  source                     = "../../modules/vpc"
  project                    = var.project
  region                     = var.region
  environment                = var.environment
  vpc_cidr_block             = var.vpc_cidr_block
  public_subnet_cidr_block   = var.public_subnet_cidr_block
  private_subnet_cidr_block  = var.private_subnet_cidr_block
  cloudnest_eks_cluster_name = local.cluster_name

  # Cross-module wiring: cloudwatch output -> vpc input
  flow_log_destination_arn = module.cloudwatch.log_group_arn
  flow_log_role_arn        = module.cloudwatch.flow_log_role_arn
}

# Security module: EKS cluster + node security groups.
# Consumes the VPC's vpc_id output (cross-module wiring).
module "security" {
  source                     = "../../modules/security"
  project                    = var.project
  environment                = var.environment
  cloudnest_eks_cluster_name = local.cluster_name

  # Cross-module wiring: vpc output -> security input
  vpc_id = module.vpc.vpc_id
}

# EKS module: control plane + node groups.
# Consumes VPC (subnets) + security (cluster SG) outputs.
module "eks" {
  source                     = "../../modules/eks"
  project                    = var.project
  environment                = var.environment
  cloudnest_eks_cluster_name = local.cluster_name
  eks_version                = var.eks_version
  node_groups                = var.node_groups

  # API endpoint exposure (tighten public_access_cidrs in dev.tfvars)
  endpoint_public_access = var.cluster_endpoint_public_access
  public_access_cidrs    = var.cluster_public_access_cidrs

  # Cross-module wiring
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security.cluster_security_group_id
}

# IRSA module: registers the cluster OIDC provider + example pod roles.
# Consumes the EKS cluster's OIDC issuer URL.
module "irsa" {
  source      = "../../modules/irsa"
  project     = var.project
  environment = var.environment

  # Cross-module wiring: eks output -> irsa input
  oidc_issuer_url = module.eks.oidc_issuer_url
}

# Addons module: vpc-cni (prefix delegation /28) + coredns + kube-proxy.
module "addons" {
  source         = "../../modules/addons"
  cluster_name   = module.eks.cluster_name
  addon_versions = var.addon_versions
  vpc_cni_config = var.vpc_cni_config
}

# EFS module: ReadWriteMany (RWX) shared storage for PVCs.
# Created ONLY when var.enable_efs = true (set enable_efs = true in dev.tfvars).
# Creates the EFS filesystem (KMS-encrypted), one mount target per AZ,
# an NFS security group locked to the node SG, the EFS CSI driver addon (IRSA),
# and a dynamic "efs-sc" StorageClass. Use storageClassName: efs-sc in PVCs.
module "efs" {
  source = "../../modules/efs"
  count  = var.enable_efs ? 1 : 0

  project     = var.project
  environment = var.environment

  # Network wiring
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  node_security_group_id = module.security.node_security_group_id

  # Cluster + IRSA wiring
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  oidc_provider_url = module.irsa.oidc_provider_url

  # Tuning from tfvars
  efs_config = var.efs_config

  # Wait for cluster networking (vpc-cni) before the CSI node DaemonSet schedules,
  # and for the access entry so the kubectl provider can authenticate (no 401).
  depends_on = [module.addons, module.access]
}

# ALB module: AWS Load Balancer Controller (IRSA role + Helm install).
# Watches Ingress objects and provisions ALBs automatically.
module "alb" {
  source       = "../../modules/alb"
  project      = var.project
  environment  = var.environment
  cluster_name = module.eks.cluster_name
  region       = var.region
  vpc_id       = module.vpc.vpc_id

  # IRSA wiring
  oidc_provider_arn = module.irsa.oidc_provider_arn
  oidc_provider_url = module.irsa.oidc_provider_url

  # Wait for vpc-cni + CoreDNS so the controller pod has networking + DNS,
  # and for the access entry so the helm provider can authenticate (no 401).
  depends_on = [module.addons, module.access]
}

# Access module: EKS Access Entries (who can use the cluster + permission level).
module "access" {
  source       = "../../modules/access"
  cluster_name = module.eks.cluster_name
  project      = var.project
  environment  = var.environment
  # Always include the Terraform runner (CI role) as cluster-admin so the
  # helm/kubectl/kubernetes providers can authenticate. User-defined entries
  # from tfvars are merged on top.
  access_entries = merge(local.terraform_runner_access, var.eks_access_entries)
  access_roles   = var.eks_access_roles
}

# ECR module: private image registry (scan, immutable, KMS, lifecycle).
# Independent of EKS - CI pushes here, nodes pull via the node role's ECR policy.
module "ecr" {
  source      = "../../modules/ecr"
  project     = var.project
  region      = var.region
  environment = var.environment

  # Repo policy principals: nodes pull, runner pushes
  node_role_arn   = module.eks.node_role_arn
  runner_role_arn = local.runner_role_arn
}

# Karpenter module: node autoscaler (controller IRSA + reused node role + SQS + Helm).
# Consumes EKS (cluster + node role) and IRSA (OIDC provider) outputs.
module "karpenter" {
  source            = "../../modules/karpenter"
  project           = var.project
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  karpenter_version = var.karpenter_version

  # IRSA wiring
  oidc_provider_arn = module.irsa.oidc_provider_arn
  oidc_provider_url = module.irsa.oidc_provider_url

  # Reuse the EKS node role (DRY)
  node_role_arn  = module.eks.node_role_arn
  node_role_name = module.eks.node_role_name

  # NodePool config from tfvars
  general_nodepool = var.general_nodepool
  gpu_nodepool     = var.gpu_nodepool
  ec2_node_classes = var.ec2_node_classes

  # Wait for vpc-cni + CoreDNS before the Karpenter controller schedules,
  # and for the access entry so the helm/kubectl providers authenticate (no 401).
  depends_on = [module.addons, module.access]
}

# RDS module: private, low-cost PostgreSQL (db.t4g.micro) + KMS + Secrets Manager.
# Consumes VPC (private subnets) + security (node SG allowed to connect).
module "rds" {
  source      = "../../modules/rds"
  project     = var.project
  environment = var.environment

  # Cross-module wiring
  private_subnet_ids = module.vpc.private_subnet_ids
  # RDS security group is created in the security module
  db_security_group_ids = [module.security.rds_security_group_id]
}

# Notifications module: KMS-encrypted SNS + email subscription + SQS/DLQ.
# CloudWatch alarms + Budgets publish here (added in later steps).
module "notifications" {
  source               = "../../modules/notifications"
  project              = var.project
  environment          = var.environment
  alert_email          = var.alert_email
  monthly_budget_limit = var.monthly_budget_limit
  cluster_name         = module.eks.cluster_name
  # Wire the live RDS instance id into the storage alarm
  rds_instance_id = module.rds.db_instance_id
}

# WAF module: REGIONAL Web ACL (CommonRuleSet + IpReputationList + rate limit).
# Attach to the ALB via the Ingress annotation: alb.ingress.kubernetes.io/wafv2-acl-arn
module "waf" {
  source      = "../../modules/waf"
  project     = var.project
  environment = var.environment
  allowed_ips = var.waf_allowed_ips
}

# Route53 module: private hosted zone cloudnest.internal linked to the VPC.
module "route53" {
  source      = "../../modules/route53"
  project     = var.project
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

# Observability module: kube-prometheus-stack (Prometheus + Alertmanager + Grafana).
# Created ONLY when var.enable_observability = true. Persistence reuses efs-sc.
module "observability" {
  source = "../../modules/observability"
  count  = var.enable_observability ? 1 : 0

  project              = var.project
  environment          = var.environment
  monitoring_namespace = var.monitoring_namespace
  storage_class        = var.storage_class

  # Loki S3 + IRSA wiring
  region            = var.region
  oidc_provider_arn = module.irsa.oidc_provider_arn
  oidc_provider_url = module.irsa.oidc_provider_url

  # All tunables sourced from dev.tfvars (no module edits needed)
  prometheus_storage_size   = var.prometheus_storage_size
  grafana_storage_size      = var.grafana_storage_size
  alertmanager_storage_size = var.alertmanager_storage_size
  loki_storage_size         = var.loki_storage_size
  chart_version             = var.kube_prometheus_chart_version
  loki_chart_version        = var.loki_chart_version
  promtail_chart_version    = var.promtail_chart_version
  log_retention_days        = var.log_retention_days
  slo_target                = var.slo_target

  # efs-sc is referenced by NAME (string), so add an explicit dependency on the
  # EFS module to guarantee the StorageClass + CSI driver exist before the
  # monitoring PVCs are created. Also needs the cluster + IRSA to be ready, and
  # the access entry so the helm/kubernetes providers authenticate (no 401).
  # CRITICAL: also wait for the ALB controller (module.alb) - its mutating
  # webhook intercepts ALL Service creation cluster-wide, so it MUST be Ready
  # before observability creates Services, and for Karpenter so there is node
  # capacity for the monitoring pods.
  depends_on = [module.efs, module.eks, module.irsa, module.addons, module.access, module.alb, module.karpenter]
}

# GitLab Runner module: stores GitLab credentials in Secrets Manager (KMS-encrypted)
# and installs the GitLab Runner via Helm. The runner registration token is read
# from Secrets Manager (set it once via the AWS CLI - see modules/gitlab-runner/secrets.tf).
module "gitlab_runner" {
  source          = "../../modules/gitlab-runner"
  project         = var.project
  environment     = var.environment
  gitlab_url      = var.gitlab_url
  gitlab_username = var.gitlab_username

  # IRSA wiring (keyless ECR push + secret read + EKS deploy)
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  oidc_provider_url = module.irsa.oidc_provider_url

  # Wait for vpc-cni + CoreDNS so runner job pods get networking + DNS,
  # and for the access entry so the helm provider can authenticate (no 401).
  depends_on = [module.addons, module.access]
}

