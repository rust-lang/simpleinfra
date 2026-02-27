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

  cpu                  = 256
  memory               = 512
  tasks_count          = 1
  platform_version     = "1.4.0"
  ephemeral_storage_gb = 40

  environment = {
    DOCSRS_PREFIX          = "/tmp"
    DOCSRS_STORAGE_BACKEND = "s3"
    DOCSRS_LOG             = "docs_rs=debug,rustwide=info"
    RUST_BACKTRACE         = "1"
    S3_REGION              = "us-east-1"
    DOCSRS_S3_BUCKET       = "${aws_s3_bucket.storage.id}"
  }

  secrets = {
    DOCSRS_GITHUB_ACCESSTOKEN = "/docs-rs/github-access-token"
  }

  computed_secrets = {
    DOCSRS_DATABASE_URL = aws_ssm_parameter.connection_url.arn
  }

  expose_http = {
    container_port = 80
    prometheus     = "/about/metrics"
    domains        = [var.cluster_config.lb_domain, var.domain]
    zone_id        = var.zone_id

    health_check_path     = "/"
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
