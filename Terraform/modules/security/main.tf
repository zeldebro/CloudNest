# =========================================================
# EKS CLUSTER (control plane) Security Group
# Created with NO cross-references inline -> avoids circular dependency
# =========================================================
resource "aws_security_group" "cloudnest_eks_cluster_sg" {
  name        = "${var.project}-${var.environment}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound (use -1 = ALL protocols, so DNS/UDP works too)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-eks-cluster-sg"
    # EKS discovery tag: marks this SG as owned by THIS cluster
    "kubernetes.io/cluster/${var.cloudnest_eks_cluster_name}" = "owned"
  }
}

# =========================================================
# EKS WORKER NODE Security Group
# Self-reference (node-to-node) is fine inline; cross-refs are separate
# =========================================================
resource "aws_security_group" "cloudnest_eks_node_sg" {
  name        = "${var.project}-${var.environment}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Node-to-node: pods talk across nodes (self reference - no cycle)
  ingress {
    description = "Node to node communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound (-1 = all protocols)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-eks-node-sg"
    # EKS discovery tag: marks this SG as owned by THIS cluster
    "kubernetes.io/cluster/${var.cloudnest_eks_cluster_name}" = "owned"
    # Karpenter discovers the node SG by this tag
    "karpenter.sh/discovery" = var.cloudnest_eks_cluster_name
  }
}

# =========================================================
# CROSS-REFERENCE RULES (separate resources break the circular dependency)
# =========================================================

# Nodes -> Cluster API server (port 443)
resource "aws_security_group_rule" "nodes_to_cluster_api" {
  type                     = "ingress"
  description              = "Allow worker nodes to reach the cluster API server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cloudnest_eks_cluster_sg.id
  source_security_group_id = aws_security_group.cloudnest_eks_node_sg.id
}

# Cluster control plane -> Node kubelet (port 10250)
resource "aws_security_group_rule" "cluster_to_nodes_kubelet" {
  type                     = "ingress"
  description              = "Allow control plane to reach node kubelet"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cloudnest_eks_node_sg.id
  source_security_group_id = aws_security_group.cloudnest_eks_cluster_sg.id
}

# =========================================================
# RDS Security Group (moved here from the rds module)
# DB firewall: egress all, ingress only from the EKS worker nodes
# =========================================================
resource "aws_security_group" "cloudnest_rds_sg" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for the CloudNest RDS instance"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-rds-sg"
  }
}

# Allow worker nodes to reach the DB (PostgreSQL 5432)
resource "aws_security_group_rule" "nodes_to_rds" {
  type                     = "ingress"
  description              = "Allow EKS worker nodes to reach the RDS database"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cloudnest_rds_sg.id
  source_security_group_id = aws_security_group.cloudnest_eks_node_sg.id
}
