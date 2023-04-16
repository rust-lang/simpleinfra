// ECS deployment and CI integration of rust-log-analyzer.

module "rla" {
  source         = "../shared/modules/ecs-app"
  cluster_config = data.terraform_remote_state.shared.outputs.ecs_cluster_config

  env  = "prod"
  name = "rust-log-analyzer"
  repo = "rust-lang/rust-log-analyzer"

  cpu              = 1024
  memory           = 2048
  tasks_count      = 1
  platform_version = "1.4.0"

  mount_efs              = "/opt/rla"
  efs_elastic_throughput = true

  environment = {
    CI_REPO     = "rust-lang/rust"
    CI_PROVIDER = "actions"
    EXTRA_ARGS  = "--secondary-repo rust-lang-ci/rust"
    GITHUB_USER = "rust-log-analyzer"
    INDEX_FILE  = "/opt/rla/rust-lang/rust/actions.idx"
    RLA_LOG     = "rla_server=trace,rust_log_analyzer=trace"
  }

  secrets = {
    GITHUB_TOKEN          = "/prod/rust-log-analyzer/github-token"
    GITHUB_WEBHOOK_SECRET = "/prod/rust-log-analyzer/webhook-secret"
  }

  expose_http = {
    container_port = 80
    domains        = ["rla.infra.rust-lang.org"]
    prometheus     = null

    health_check_path     = "/"
    health_check_interval = 5
    health_check_timeout  = 2
  }
}

resource "aws_s3_bucket" "storage" {
   bucket = "rust-log-analyzer-storage"
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "storage" {
  bucket = aws_s3_bucket.storage.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "multipart-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_iam_role_policy" "storage" {
  name = "storage-access"
  role = module.rla.role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.storage.arn}/*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
      },
      {
        Effect   = "Allow"
        Resource = "*"
        Action   = "s3:GetBucketLocation"
      }
    ]
  })
}
