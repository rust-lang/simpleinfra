resource "aws_iam_role" "start_release" {
  name = "start-release-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "codebuild:StartBuild",
            "codebuild:BatchGetBuilds",
          ]
          Resource = [
            module.dev.codebuild_project_arn,
            module.prod.codebuild_project_arn,
          ]
        }
      ]
    })
  }
}

module "lambda_start_release" {
  source = "../shared/modules/lambda"

  name            = "start-release"
  source_dir      = "lambdas/start-release"
  handler         = "index.handler"
  runtime         = "python3.12"
  role_arn        = aws_iam_role.start_release.arn
  timeout_seconds = 900 # 15 minutes
}
