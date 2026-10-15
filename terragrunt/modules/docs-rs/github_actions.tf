module "gh_oidc" {
  source = "../gha-oidc-provider"
}

resource "aws_iam_role_policy_attachment" "admin_ci_push" {
  role       = module.web.ci_role_name
  policy_arn = module.admin.policy_push_arn
}

# BuildKit also reads image manifests when pushing images and attestations.
resource "aws_iam_role_policy_attachment" "admin_ci_pull" {
  role       = module.web.ci_role_name
  policy_arn = module.admin.policy_pull_arn
}

# The web app's CI role can deploy its ECS service, but cannot launch standalone
# tasks. Extend that same GitHub deployment role so the deploy action can
# register a release task revision, run it, check completion, and pass the
# shared admin/release runtime and execution roles to ECS.
resource "aws_iam_role_policy" "admin_ci" {
  name = "run-admin-task"
  role = module.web.ci_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ecs:RunTask"]
        Resource = [
          "${replace(aws_ecs_task_definition.release.arn, "/:[0-9]+$/", "")}:*",
        ]
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.cluster_config.cluster_id
          }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks"]
        Resource = "${replace(var.cluster_config.cluster_id, ":cluster/", ":task/")}/*"
        Condition = {
          ArnEquals = {
            "ecs:cluster" = var.cluster_config.cluster_id
          }
        }
      },
      {
        # RegisterTaskDefinition does not support resource-level permissions.
        # PassRole below limits which roles the registered task can use.
        Effect   = "Allow"
        Action   = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [module.admin.task_role_arn, module.admin.execution_role_arn]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
    ]
  })
}
