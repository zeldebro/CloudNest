# This file defines the IAM role and policies for EKS worker nodes.
data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "cloudenest_eks_node_role" {
  name               = "${var.project}-${var.environment}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

# WHAT it can do: ATTACH 3 AWS-managed policies (Join / Network / Pull)
# 1) Join the cluster
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.cloudenest_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# 2) Pod networking (VPC CNI assigns pod IPs)
resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.cloudenest_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# 3) Pull container images from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  role       = aws_iam_role.cloudenest_eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
