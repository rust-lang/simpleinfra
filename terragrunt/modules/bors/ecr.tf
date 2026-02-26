resource "aws_ecr_repository" "primary" {
  name                 = "bors"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.primary.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.gha.arn
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.primary.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete 14 days after untagged"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
