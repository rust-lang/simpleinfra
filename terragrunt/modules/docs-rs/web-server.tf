resource "aws_security_group" "web" {
  vpc_id = var.cluster_config.vpc_id
  name   = "docs-rs-web"
}

module "web" {
  source         = "../ecs-app"
  cluster_config = var.cluster_config

  github_environment = var.github_environment
  gh_oidc_arn        = module.gh_oidc.arn
  name               = "docs-rs-web"
  repo               = "rust-lang/docs.rs"

  cpu                  = 1024
  memory               = 2048
  tasks_count          = var.web_count
  platform_version     = "1.4.0"
  ephemeral_storage_gb = 40

  # The image defaults to port 3000; the ECS service and ALB target port 80.
  command = ["0.0.0.0:80"]

  environment = merge(local.common_environment, {
    DOCSRS_AWS_SDK_MAX_RETRIES                 = "10"
    DOCSRS_ARCHIVE_INDEX_CACHE_EVICTION_POLICY = "lru"

    # Leave space for the image and other files on the 40 GiB task disk.
    DOCSRS_ARCHIVE_INDEX_CACHE_MAX_SIZE = "10GiB"

    DOCSRS_REQUEST_TIMEOUT               = "120s"
    DOCSRS_REPORT_REQUEST_TIMEOUTS       = "true"
    CACHE_CONTROL_STALE_WHILE_REVALIDATE = "1d"

    # No CDN invalidation worker is configured for this web deployment.
    DOCSRS_CACHE_INVALIDATEABLE_RESPONSES = "false"

    # Size concurrency for the 0.25 vCPU web task, rather than the legacy daemon.
    DOCSRS_RENDER_THREADS = "1"
    DOCSRS_MIN_POOL_IDLE  = "1"
    DOCSRS_MAX_POOL_SIZE  = "10"
  })

  computed_secrets = local.common_computed_secrets

  expose_http = {
    container_port = 80
    prometheus     = null
    domains        = [var.cluster_config.lb_domain, var.domain]
    zone_id        = var.zone_id

    health_check_path     = "/-/health"
    health_check_interval = 5
    health_check_timeout  = 2
  }

  # Allow database access
  additional_security_group_ids = [aws_security_group.web.id]
}

resource "aws_iam_role_policy" "web" {
  role = module.web.role_id
  name = "inline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectTagging",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.storage.arn,
          "${aws_s3_bucket.storage.arn}/*",
        ]
      }
    ]
  })
}
