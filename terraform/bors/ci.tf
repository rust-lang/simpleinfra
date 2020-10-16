// Resources used by the rust-lang/homu CI.

module "ecr" {
  source = "../shared/modules/ecr-repo"
  name   = "bors"
}

module "iam_ci" {
  source = "../shared/modules/gha-iam-user"
  org    = "rust-lang"
  repo   = "homu"
}

resource "aws_iam_user_policy" "update_service" {
  name = "update-ecs-service"
  user = module.iam_ci.user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowUpdate"
        Effect   = "Allow"
        Action   = "ecs:UpdateService"
        Resource = module.ecs_service.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "ci_pull" {
  user       = module.iam_ci.user_name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = module.iam_ci.user_name
  policy_arn = module.ecr.policy_push_arn
}
