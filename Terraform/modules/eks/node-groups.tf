# =========================================================
# Managed node groups - ONE resource, loops over var.node_groups.
# Add a new group = add a map entry in tfvars. No changes here.
# =========================================================
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cloudnest_eks_cluster.name
  node_group_name = "${var.project}-${var.environment}-${each.key}"
  node_role_arn   = aws_iam_role.cloudenest_eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  # --- per-group settings pulled from the map (each.value) ---
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type
  disk_size      = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  labels = each.value.labels

  # Taints (e.g. GPU nodes repel normal pods). Loops over the group's taint list.
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  update_config {
    max_unavailable = 1
  }

  # Nodes must have their IAM policies BEFORE they try to join the cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
  ]
}

