# =========================================================
# EFS security group - allows NFS (2049) ONLY from the EKS node SG.
# Never open to the VPC/world; the node SG is the single allowed source.
# =========================================================
resource "aws_security_group" "efs" {
  name        = "${var.project}-${var.environment}-efs-sg"
  description = "Allow NFS 2049 from EKS nodes to EFS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.environment}-efs-sg"
  }
}

# Ingress: NFS from worker nodes only
resource "aws_security_group_rule" "efs_ingress_nfs" {
  type                     = "ingress"
  description              = "NFS from EKS worker nodes (custom node SG)"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = var.node_security_group_id
}

# Ingress: NFS from the EKS-managed cluster SG that nodes ACTUALLY use.
# Without this the pods can't reach EFS and mounts fail with DeadlineExceeded.
resource "aws_security_group_rule" "efs_ingress_nfs_cluster_sg" {
  type                     = "ingress"
  description              = "NFS from EKS cluster security group (real node SG)"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = var.cluster_primary_security_group_id
}

# Egress: allow return traffic
resource "aws_security_group_rule" "efs_egress" {
  type              = "egress"
  description       = "Allow all egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

