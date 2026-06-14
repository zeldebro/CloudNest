# Who is allowed to assume this role: the VPC Flow Logs AWS service
data "aws_iam_policy_document" "vpc_flow_log_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

# The IAM role itself (identity)
resource "aws_iam_role" "vpc_flow_log_role" {
  name               = "${var.project}-${var.environment}-vpc-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume_role_policy.json
}

# What the role is ALLOWED to do: write to CloudWatch Logs (permissions)
data "aws_iam_policy_document" "vpc_flow_log_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# Attach the permissions policy to the role
resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name   = "${var.project}-${var.environment}-vpc-flow-log-policy"
  role   = aws_iam_role.vpc_flow_log_role.id
  policy = data.aws_iam_policy_document.vpc_flow_log_permissions.json
}
