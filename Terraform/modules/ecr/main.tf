# =========================================================
# ECR repository - private image registry (production-grade).
# =========================================================
resource "aws_ecr_repository" "cloudnest_ecr_repo" {
  name = "${var.project}-${var.environment}-ecr-repo"

  # Immutable tags = a tag can't be overwritten (supply-chain safety)
  image_tag_mutability = "IMMUTABLE"

  # Scan images for CVEs on every push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest with KMS
  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = "${var.project}-${var.environment}-ecr-repo"
  }
}

resource "aws_ecr_lifecycle_policy" "cloudnest_ecr_lifecycle_policy" {
  repository = aws_ecr_repository.cloudnest_ecr_repo.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 30 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 20 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
