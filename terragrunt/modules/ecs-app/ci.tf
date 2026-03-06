locals {
  github_org   = split("/", var.repo)[0]
  github_repo  = split("/", var.repo)[1]
  oidc_role_id = module.gh_oidc_ci.role.id
}

// OIDC role for GitHub Actions used to push/pull images from ECR and
// restart the ECS service once the image is uploaded.
module "gh_oidc_ci" {
  source               = "../gha-oidc-role"
  org                  = local.github_org
  repo                 = local.github_repo
  environment          = var.github_environment
  oidc_provider_arn    = var.gh_oidc_arn
  lookup_oidc_provider = false
}

resource "aws_iam_role_policy" "oidc_update_service" {
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
  role       = local.oidc_role_id
  policy_arn = module.ecs_task.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "oidc_ci_push" {
  role       = local.oidc_role_id
  policy_arn = module.ecs_task.policy_push_arn
}
