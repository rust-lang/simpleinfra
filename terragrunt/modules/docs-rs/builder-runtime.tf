locals {
  builder_asg_name       = "docs-rs-builders"
  builder_launch_hook    = "builder-ready"
  builder_prefix_path    = "/opt/docs-rs/prefix"
  builder_workspace_path = "/opt/docs-rs/workspace"
  builder_image = format(
    "%s%s%s", module.builder_ecr.url,
    startswith(var.builder_image_version, "sha256:") ? "@" : ":", var.builder_image_version,
  )
  builder_environment = { for name, value in merge(local.common_environment, {
    DOCSRS_PREFIX                                    = local.builder_prefix_path
    DOCSRS_RUSTWIDE_WORKSPACE                        = local.builder_workspace_path
    DOCSRS_DOCKER                                    = true
    DOCSRS_DOCKER_RUNTIME                            = "runsc"
    DOCSRS_TOOLCHAIN                                 = "nightly"
    DOCSRS_LOG                                       = "info,rustwide=info"
    DOCSRS_MIN_POOL_IDLE                             = 1
    DOCSRS_MAX_POOL_SIZE                             = 4
    DOCSRS_LOG_BUILD_LOGS                            = false
    DOCSRS_AWS_SDK_MAX_RETRIES                       = 10
    DOCSRS_INCLUDE_DEFAULT_TARGETS                   = false
    DOCSRS_BUILD_CPU_LIMIT                           = var.builder_config.build_cpu_limit
    DOCSRS_BUILD_DEFAULT_MEMORY_LIMIT                = var.builder_config.build_memory_limit
    DOCSRS_BUILD_WORKSPACE_REINITIALIZATION_INTERVAL = "2h"
  }) : name => tostring(value) }
}

resource "aws_iam_role_policy_attachment" "builder_ecr_pull" {
  role       = aws_iam_role.builder.name
  policy_arn = module.builder_ecr.policy_pull_arn
}

resource "aws_cloudwatch_log_group" "builder" {
  name              = "/ecs/docs-rs-builder"
  retention_in_days = 7
}

resource "aws_iam_role_policy" "builder_startup" {
  name = "builder-startup"
  role = aws_iam_role.builder.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          aws_ssm_parameter.connection_url.arn,
          local.github_token_arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.builder.arn}:*"
      },
      {
        Effect   = "Allow"
        Action   = ["autoscaling:CompleteLifecycleAction"]
        Resource = "arn:${data.aws_partition.builder.partition}:autoscaling:${data.aws_region.builder.region}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.builder_asg_name}"
      },
    ]
  })
}
