# =========================================================
# DB subnet group - places the instance in PRIVATE subnets
# =========================================================
resource "aws_db_subnet_group" "cloudnest_rds" {
  name       = "${var.project}-${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-rds-subnet-group"
  }
}

# =========================================================
# RDS instance - single, low-cost PostgreSQL (db.t4g.micro)
# Security group is provided by the security module (var.db_security_group_ids)
# =========================================================
resource "aws_db_instance" "cloudnest_rds" {
  identifier     = "${var.project}-${var.environment}-rds"
  engine         = "postgres"
  engine_version = var.engine_version

  # Lowest-cost: single small instance, minimal gp3 storage, no Multi-AZ
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  multi_az          = false

  db_name  = var.db_name
  username = var.db_username
  password = random_password.cloudnest_rds_password.result
  port     = var.db_port

  # Encryption at rest with the module's KMS key
  storage_encrypted = true
  kms_key_id        = aws_kms_key.cloudnest_rds_kms_key.arn

  # Private only
  db_subnet_group_name   = aws_db_subnet_group.cloudnest_rds.name
  vpc_security_group_ids = var.db_security_group_ids
  publicly_accessible    = false

  # Keep costs/footprint low for dev
  backup_retention_period = 1    # 1 day of automated backups
  skip_final_snapshot     = true # no final snapshot on destroy (dev)
  deletion_protection     = false

  tags = {
    Name = "${var.project}-${var.environment}-rds"
  }
}