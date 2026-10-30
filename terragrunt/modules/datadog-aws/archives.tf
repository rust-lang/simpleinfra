locals {
  datadog_archives_enabled = var.datadog_archives != null
}

resource "aws_s3_bucket" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  bucket = var.datadog_archives.bucket
}

// Disable versioning
resource "aws_s3_bucket_versioning" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  bucket = aws_s3_bucket.datadog_archives[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

// 1-year archive retention
resource "aws_s3_bucket_lifecycle_configuration" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  bucket = aws_s3_bucket.datadog_archives[0].id

  rule {
    id     = "yearly-delete"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      days = 330
    }
  }
}

resource "aws_s3_bucket_public_access_block" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  bucket = aws_s3_bucket.datadog_archives[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  name = "DatadogLogArchives"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DatadogUploadAndRehydrateLogArchives"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = ["${aws_s3_bucket.datadog_archives[0].arn}/*"]
      },
      {
        Sid    = "DatadogRehydrateLogArchivesListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.datadog_archives[0].arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datadog_archives" {
  count = local.datadog_archives_enabled ? 1 : 0

  role       = aws_iam_role.datadog.name
  policy_arn = aws_iam_policy.datadog_archives[0].arn
}

resource "datadog_logs_archive" "s3_archive" {
  for_each = local.datadog_archives_enabled ? var.datadog_archives.services : {}

  name = each.key
  // Some service names are shared with staging/dev, so restrict to this account's env
  query        = "service:${each.value} env:${var.env}"
  include_tags = true

  s3_archive {
    bucket     = aws_s3_bucket.datadog_archives[0].bucket
    path       = "/${each.key}"
    account_id = datadog_integration_aws_account.aws.aws_account_id
    role_name  = aws_iam_role.datadog.name
  }
}
