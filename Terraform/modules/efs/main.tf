# =========================================================
# EFS filesystem for ReadWriteMany (RWX) PVCs.
# KMS-encrypted at rest (mirrors the RDS module pattern).
# Mount targets: ONE per private subnet so pods in every AZ can mount.
# =========================================================

# --- KMS key for EFS encryption at rest ---
resource "aws_kms_key" "efs" {
  description             = "KMS key for encrypting CloudNest EFS filesystems"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "efs" {
  target_key_id = aws_kms_key.efs.id
  name          = "alias/${var.project}/${var.environment}/efs"
}

# --- The elastic filesystem ---
resource "aws_efs_file_system" "this" {
  creation_token = "${var.project}-${var.environment}-efs"
  encrypted      = true
  kms_key_id     = aws_kms_key.efs.arn

  performance_mode = var.efs_config.performance_mode
  throughput_mode  = var.efs_config.throughput_mode

  # Move cold files to Infrequent Access to save cost; pull back on access.
  lifecycle_policy {
    transition_to_ia = var.efs_config.transition_to_ia
  }

  dynamic "lifecycle_policy" {
    for_each = var.efs_config.transition_to_primary_on_access ? [1] : []
    content {
      transition_to_primary_storage_class = "AFTER_1_ACCESS"
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-efs"
  }
}

# --- Mount targets: one ENI per private subnet/AZ ---
# A pod can ONLY mount EFS if its AZ has a mount target. One per subnet = all AZs covered.
resource "aws_efs_mount_target" "this" {
  for_each = toset(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

