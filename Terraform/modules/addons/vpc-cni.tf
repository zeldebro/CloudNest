# =========================================================
# VPC CNI addon - pod networking with PREFIX DELEGATION (/28 blocks).
# configuration_values passes env settings to the aws-node DaemonSet.
# =========================================================
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = var.cluster_name
  addon_name    = "vpc-cni"
  addon_version = var.addon_versions.vpc_cni

  # Overwrite the default config EKS ships with
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    env = {
      # /28 prefix delegation - 16 IPs per ENI slot (~110 pods/node)
      ENABLE_PREFIX_DELEGATION = tostring(var.vpc_cni_config.enable_prefix_delegation)
      # keep N spare /28 prefixes ready for fast pod startup
      WARM_PREFIX_TARGET = tostring(var.vpc_cni_config.warm_prefix_target)
      # security groups for pods (per-pod SGs) - optional
      ENABLE_POD_ENI = tostring(var.vpc_cni_config.enable_pod_eni)
    }
    # cap the aws-node DaemonSet so it can't starve nodes
    resources = {
      requests = { cpu = "25m", memory = "64Mi" }
    }
  })
}

