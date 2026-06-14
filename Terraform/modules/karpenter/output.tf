output "controller_role_arn" {
  description = "ARN of the Karpenter controller IRSA role"
  value       = aws_iam_role.controller.arn
}

output "node_role_arn" {
  description = "ARN of the node role (reused from EKS) used by EC2NodeClass"
  value       = var.node_role_arn
}

output "node_instance_profile_name" {
  description = "Instance profile name for Karpenter-launched nodes"
  value       = aws_iam_instance_profile.node.name
}

output "interruption_queue_name" {
  description = "SQS interruption queue name"
  value       = aws_sqs_queue.interruption.name
}

