# =========================================================
# EFS module outputs
# =========================================================
output "efs_id" {
  description = "EFS filesystem ID (use in static PV definitions if needed)"
  value       = aws_efs_file_system.this.id
}

output "efs_arn" {
  description = "EFS filesystem ARN"
  value       = aws_efs_file_system.this.arn
}

output "efs_dns_name" {
  description = "EFS mount DNS name"
  value       = aws_efs_file_system.this.dns_name
}

output "efs_security_group_id" {
  description = "Security group ID attached to the EFS mount targets"
  value       = aws_security_group.efs.id
}

output "storage_class_name" {
  description = "Name of the RWX StorageClass to put in PVC.spec.storageClassName"
  value       = var.storage_class_name
}

output "efs_csi_role_arn" {
  description = "IRSA role ARN used by the EFS CSI driver"
  value       = aws_iam_role.efs_csi.arn
}

