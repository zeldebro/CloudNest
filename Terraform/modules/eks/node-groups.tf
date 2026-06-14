# =========================================================
# Managed node groups - ONE resource, loops over var.node_groups.
# Add a new group = add a map entry in tfvars. No changes here.
# =========================================================

# Standard tags applied to the EC2 instances/volumes/ENIs the node group
# launches. NOTE: provider default_tags do NOT reach these (the ASG creates
# them at runtime, not Terraform), so we set them explicitly via the launch
# template's tag_specifications below.
locals {
  node_instance_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Launch template per node group: the ONLY way to tag node-group EC2 instances,
# volumes and ENIs. Also enforces IMDSv2 + encrypted gp3 root volumes.
resource "aws_launch_template" "node" {
  for_each = var.node_groups

  name_prefix = "${var.project}-${var.environment}-${each.key}-"

  # Encrypted gp3 root volume (disk_size moves here from the node group).
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value.disk_size
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # Require IMDSv2 (blocks SSRF credential theft).
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Tag EVERYTHING the ASG launches from this template.
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.node_instance_tags, {
      Name = "${var.project}-${var.environment}-${each.key}-node"
    })
  }
  tag_specifications {
    resource_type = "volume"
    tags = merge(local.node_instance_tags, {
      Name = "${var.project}-${var.environment}-${each.key}-vol"
    })
  }
  tag_specifications {
    resource_type = "network-interface"
    tags = merge(local.node_instance_tags, {
      Name = "${var.project}-${var.environment}-${each.key}-eni"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.cloudnest_eks_cluster.name
  node_group_name = "${var.project}-${var.environment}-${each.key}"
  node_role_arn   = aws_iam_role.cloudenest_eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  # --- per-group settings pulled from the map (each.value) ---
  # NOTE: disk_size is NOT set here - it lives in the launch template's
  # block_device_mappings (setting both is an error). ami_type/instance_types/
  # capacity_type stay here so EKS still manages the right AMI.
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type

  # Use the launch template so instances/volumes/ENIs get tagged + IMDSv2.
  launch_template {
    id      = aws_launch_template.node[each.key].id
    version = aws_launch_template.node[each.key].latest_version
  }

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

