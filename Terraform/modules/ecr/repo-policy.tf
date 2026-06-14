# =========================================================
# ECR repository policy - LEAST PRIVILEGE.
# Node role  -> PULL only (read images to run pods)
# Runner role -> PUSH (+pull) (CI builds & uploads images)
# Note: ecr:GetAuthorizationToken is account-level (granted via IAM, not here).
# =========================================================
resource "aws_ecr_repository_policy" "cloudnest_ecr_policy" {
  repository = aws_ecr_repository.cloudnest_ecr_repo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "NodesPullOnly"
        Effect = "Allow"
        Principal = {
          AWS = var.node_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "RunnerPush"
        Effect = "Allow"
        Principal = {
          AWS = var.runner_role_arn
        }
        Action = [
          # pull (CI may need to pull base layers)
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          # push
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
      }
    ]
  })
}

