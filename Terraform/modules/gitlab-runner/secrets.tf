# =========================================================
# GitLab credentials stored in AWS Secrets Manager
#
# Stores the GitLab username + a GENERATED password as an encrypted
# JSON secret. Pods/CI read it at runtime via IRSA - the raw values
# are NEVER hardcoded in manifests.
# =========================================================

# Dedicated KMS key so we control encryption of the GitLab secret
resource "aws_kms_key" "gitlab" {
  description             = "KMS key for encrypting GitLab credentials in Secrets Manager"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "gitlab" {
  name          = "alias/${var.project}/${var.environment}/gitlab"
  target_key_id = aws_kms_key.gitlab.id
}

# Generated password (so we never hardcode one)
resource "random_password" "gitlab" {
  length           = 24
  override_special = "!#$%^&*()-_=+[]{}"
  special          = true
}

# Secret container (encrypted with the KMS key above)
resource "aws_secretsmanager_secret" "gitlab" {
  name        = "${var.project}-${var.environment}-gitlab-credentials"
  description = "GitLab username/password for CI/CD"
  kms_key_id  = aws_kms_key.gitlab.arn
  # 0 = delete immediately on destroy so a re-apply with the same name
  # doesn't fail with "secret scheduled for deletion" (dev-friendly)
  recovery_window_in_days = 0
}

# Secret content - the actual values as JSON
resource "aws_secretsmanager_secret_version" "gitlab" {
  secret_id = aws_secretsmanager_secret.gitlab.id
  secret_string = jsonencode({
    username = var.gitlab_username
    password = random_password.gitlab.result
    url      = var.gitlab_url
  })
}

# =========================================================
# Runner registration token - stored in Secrets Manager.
# Terraform creates the CONTAINER with a placeholder; you set the REAL
# token ONCE out-of-band (so it's never in code, env, or CI):
#
#   aws secretsmanager put-secret-value \
#     --secret-id cloudnest-dev-gitlab-runner-token \
#     --secret-string '{"token":"glrt-xxxxxxxx"}'
#
# lifecycle ignore_changes => Terraform won't overwrite your real token.
# =========================================================
resource "aws_secretsmanager_secret" "runner_token" {
  name                    = "${var.project}-${var.environment}-gitlab-runner-token"
  description             = "GitLab runner registration token"
  kms_key_id              = aws_kms_key.gitlab.arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "runner_token" {
  secret_id     = aws_secretsmanager_secret.runner_token.id
  secret_string = jsonencode({ token = "REPLACE_ME" })

  lifecycle {
    ignore_changes = [secret_string] # token is set manually, don't revert it
  }
}

# Read the (manually-set) token back so the Helm release can use it
data "aws_secretsmanager_secret_version" "runner_token" {
  secret_id  = aws_secretsmanager_secret.runner_token.id
  depends_on = [aws_secretsmanager_secret_version.runner_token]
}

