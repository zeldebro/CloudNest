# =========================================================
# Outputs - consumed by root (notifications alarm), apps, IAM
# =========================================================
output "db_instance_id" {
  description = "RDS DBInstanceIdentifier (fed to the notifications storage alarm)"
  value       = aws_db_instance.cloudnest_rds.identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.cloudnest_rds.arn
}

output "db_endpoint" {
  description = "Connection endpoint (host:port)"
  value       = aws_db_instance.cloudnest_rds.endpoint
}

output "db_address" {
  description = "DNS hostname of the instance"
  value       = aws_db_instance.cloudnest_rds.address
}

output "db_port" {
  description = "Port the database listens on"
  value       = aws_db_instance.cloudnest_rds.port
}

output "db_security_group_ids" {
  description = "Security group IDs attached to the RDS instance (created in the security module)"
  value       = var.db_security_group_ids
}

# ARN only - never expose the password value
output "db_credentials_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials"
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key encrypting RDS storage + the secret"
  value       = aws_kms_key.cloudnest_rds_kms_key.arn
}

