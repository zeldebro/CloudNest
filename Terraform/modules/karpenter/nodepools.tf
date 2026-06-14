# =========================================================
# Apply Karpenter CRDs (EC2NodeClass + NodePools) AFTER the controller installs.
# Uses kubectl_manifest (gavinbunney) - no plan-time CRD validation, so it
# avoids the chicken-and-egg problem of hashicorp's kubernetes_manifest.
# =========================================================

# The node blueprints - one per entry in var.ec2_node_classes (default + gpu)
resource "kubectl_manifest" "ec2nodeclass" {
  for_each = var.ec2_node_classes

  yaml_body = templatefile("${path.module}/manifests/ec2nodeclass.yaml.tpl", {
    name           = each.key
    node_role_name = var.node_role_name
    cluster_name   = var.cluster_name
    ami_alias      = each.value.ami_alias
    disk_size      = each.value.disk_size
    project        = var.project
    environment    = var.environment
  })

  depends_on = [helm_release.cloudnest_karpenter] # CRDs must exist first
}

# CPU NodePool -> uses the "default" blueprint
resource "kubectl_manifest" "nodepool_general" {
  yaml_body = templatefile("${path.module}/manifests/nodepool-general.yaml.tpl", {
    node_class_name     = "default"
    capacity_types      = var.general_nodepool.capacity_types
    instance_categories = var.general_nodepool.instance_categories
    cpu_limit           = var.general_nodepool.cpu_limit
    memory_limit        = var.general_nodepool.memory_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass]
}

# GPU NodePool -> uses the "gpu" blueprint (bigger disk, GPU AMI)
resource "kubectl_manifest" "nodepool_gpu" {
  yaml_body = templatefile("${path.module}/manifests/nodepool-gpu.yaml.tpl", {
    node_class_name   = "gpu"
    capacity_types    = var.gpu_nodepool.capacity_types
    instance_families = var.gpu_nodepool.instance_families
    gpu_limit         = var.gpu_nodepool.gpu_limit
  })

  depends_on = [kubectl_manifest.ec2nodeclass]
}

