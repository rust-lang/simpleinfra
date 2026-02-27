locals {
  github_org   = split("/", var.repo)[0]
  github_repo  = split("/", var.repo)[1]
  oidc_role_id = module.gh_oidc_ci[0].role.id
}

// IAM User used by GitHub Actions to pull and push images to ECR, and to
// restart the ECS service once the image is uploaded. The credentials will
// be added automatically to the GitHub Actions secrets.

module "iam_ci" {
  source     = "../gha-iam-user"
  org        = local.github_org
  repo       = local.github_repo
  env_prefix = var.github_environment == "staging" ? "STAGING" : null
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
  policy_arn = module.ecs_task.policy_pull_arn
}

resource "aws_iam_user_policy_attachment" "ci_push" {
  user       = module.iam_ci.user_name
  policy_arn = module.ecs_task.policy_push_arn
}

// Optional OIDC role for GitHub Actions. This can be used instead of static
// AWS credentials when workflows run in a GitHub environment.
module "gh_oidc_ci" {
  count = var.github_environment != null ? 1 : 0

  source               = "../gha-oidc-role"
  org                  = local.github_org
  repo                 = local.github_repo
  environment          = var.github_environment
  oidc_provider_arn    = var.gh_oidc_arn
  lookup_oidc_provider = false
}

resource "aws_iam_role_policy" "oidc_update_service" {
  count = var.github_environment != null ? 1 : 0

  name = "update-ecs-service"
  role = local.oidc_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUpdate"
        Effect = "Allow"
        Action = [
          # Get authorization to pull and push images
          "ecr:GetAuthorizationToken",
          # Update the service to trigger a new deployment
          "ecs:UpdateService",
          # Used to wait until the service is stable
          "ecs:DescribeServices"
        ]
        Resource = module.ecs_service.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "oidc_ci_pull" {
  count = var.github_environment != null ? 1 : 0

  role       = local.oidc_role_id
  policy_arn = module.ecs_task.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "oidc_ci_push" {
  count = var.github_environment != null ? 1 : 0

  role       = local.oidc_role_id
  policy_arn = module.ecs_task.policy_push_arn
}
