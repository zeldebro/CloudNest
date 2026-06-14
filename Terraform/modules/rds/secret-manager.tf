resource "random_password" "cloudnest_rds_password" {
  length = 24
  # RDS rejects /, @, ", and spaces in the master password
  override_special = "!#$%^&*()-_=+[]{}"
  special          = true
}

# Secret container - encrypted with the RDS KMS key
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${var.project}-${var.environment}-rds-credentials"
  description = "Master credentials for the CloudNest RDS instance"
  kms_key_id  = aws_kms_key.cloudnest_rds_kms_key.arn
  # 0 = delete immediately on destroy so a re-apply with the same name
  # doesn't fail with "secret scheduled for deletion" (dev-friendly)
  recovery_window_in_days = 0
}

# Secret content - the actual values stored as JSON
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.cloudnest_rds_password.result
    engine   = "postgres"
    host     = aws_db_instance.cloudnest_rds.address
    port     = var.db_port
    dbname   = var.db_name
  })
}
