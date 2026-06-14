# This file defines the IAM role for the EKS CLUSTER (control plane).
data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "cloudenest_eks_cluster_role" {
  name               = "${var.project}-${var.environment}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cloudenest_eks_cluster_policy" {
  role       = aws_iam_role.cloudenest_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
