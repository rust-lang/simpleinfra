# The watcher is a long-running background daemon (docs_rs_watcher binary) that:
# - polls the crates.io registry index for new crate publishes and queues builds
# - periodically updates GitHub/GitLab repository stats
# - queues automatic rebuilds of old releases

# Dedicated security group so we can grant the watcher DB access
resource "aws_security_group" "watcher" {
  vpc_id = var.cluster_config.vpc_id
  name   = "docs-rs-watcher"
}

# The watcher doesn't serve HTTP, so we use ecs-task + raw aws_ecs_service directly
# instead of the ecs-app module, which requires expose_http and always creates
# a load balancer target group.
module "watcher_task" {
  source = "../ecs-task"

  name           = "docs-rs-watcher"
  container_name = "app"
  cpu            = 256
  memory         = 512

  environment_variables = {
    DOCSRS_PREFIX       = "/tmp"
    REGISTRY_INDEX_PATH = "/tmp/crates.io-index"

    DOCSRS_STORAGE_BACKEND = "s3"
    S3_REGION              = "us-east-1"
    DOCSRS_S3_BUCKET       = aws_s3_bucket.storage.id

    DOCSRS_LOG     = "docs_rs=debug,rustwide=info"
    RUST_BACKTRACE = "1"

    # - How often to poll the registry for new crates (seconds)
    DOCSRS_DELAY_BETWEEN_REGISTRY_FETCHES = "60"
    # - Cap on how many old releases to queue for rebuild per hourly cycle
    DOCSRS_MAX_QUEUED_REBUILDS = "10"
  }

  secrets = {
    # Used by docs_rs_repository_stats to call the GitHub API when updating
    # repository stars/forks/etc.
    DOCSRS_GITHUB_ACCESSTOKEN = "/docs-rs/github-access-token"
  }

  computed_secrets = {
    # The watcher needs direct DB access: it writes to the build queue,
    # updates repository stats, and runs consistency checks.
    DOCSRS_DATABASE_URL = aws_ssm_parameter.connection_url.arn
  }

  # No HTTP — the watcher is a background daemon with no exposed ports.
  port_mappings = []
  docker_labels = {}
}

resource "aws_ecs_service" "watcher" {
  name            = "docs-rs-watcher"
  cluster         = var.cluster_config.cluster_id
  task_definition = module.watcher_task.task_arn
  # Exactly 1 replica: the registry watcher must be a singleton, otherwise
  # crates would be added to the build queue multiple times.
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  enable_ecs_managed_tags = true

  # No load_balancer block — the watcher has no HTTP endpoint.
  network_configuration {
    subnets = var.cluster_config.subnet_ids
    security_groups = [
      var.cluster_config.service_security_group_id,
      aws_security_group.watcher.id,
    ]
    # Public IP needed to reach external services (crates.io index, GitHub API,
    # ECR, SSM) without NAT gateway — same pattern as the web service.
    assign_public_ip = true
  }
}

# S3 permissions: the watcher deletes documentation from S3 when removing
# crates/versions (delete_crate, delete_version) and reads/writes via the
# storage abstraction layer.
resource "aws_iam_role_policy" "watcher_s3" {
  role = module.watcher_task.task_execution_role_id
  name = "inline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:GetObject",
          "s3:PutObjectAcl",
          "s3:ListBucket",
          "s3:DeleteObject",
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*",
        ]
      }
    ]
  })
}

# CI: reuse the web module's OIDC role rather than creating a new one.
# The gha-oidc-role module derives the IAM role name from org/repo/environment,
# so a second module instance for the same rust-lang/docs.rs repo would
# conflict. Instead we attach the watcher's ECR and ECS permissions to the
# existing role.
resource "aws_iam_role_policy" "watcher_oidc_update_service" {
  name = "update-ecs-service-watcher"
  role = module.web.oidc_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowUpdate"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        Resource = aws_ecs_service.watcher.id
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "watcher_oidc_ci_pull" {
  role       = module.web.oidc_role_id
  policy_arn = module.watcher_task.policy_pull_arn
}

resource "aws_iam_role_policy_attachment" "watcher_oidc_ci_push" {
  role       = module.web.oidc_role_id
  policy_arn = module.watcher_task.policy_push_arn
}
