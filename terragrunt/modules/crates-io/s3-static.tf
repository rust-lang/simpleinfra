resource "aws_s3_bucket" "static" {
  bucket = var.static_bucket_name

  versioning {
    enabled = true
  }

  // Allow the crates.io frontend to fetch the READMEs from JavaScript.
  cors_rule {
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  // Keep only the live db-dumps and the previous day's versions, removing
  // all the other ones. This is needed because we don't want this file to be
  // versioned, while all the other ones in the bucket should be versioned.
  lifecycle_rule {
    id      = "purge-db-dump"
    enabled = true
    prefix  = "db-dump.tar.gz"

    abort_incomplete_multipart_upload_days = 1
    noncurrent_version_expiration {
      days = 1
    }
  }

  lifecycle_rule {
    id      = "purge-db-dump-zip"
    enabled = true
    prefix  = "db-dump.zip"

    abort_incomplete_multipart_upload_days = 1
    noncurrent_version_expiration {
      days = 1
    }
  }

  lifecycle {
    ignore_changes = [
      replication_configuration,
    ]
  }
}

resource "aws_s3_bucket_replication_configuration" "static" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.static.id

  rule {
    id     = "crates"
    status = "Enabled"

    filter {
      prefix = "crates/"
    }

    destination {
      bucket        = aws_s3_bucket.fallback.arn
      storage_class = "INTELLIGENT_TIERING"

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PublicReadGetObject",
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_inventory" "static" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.static.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "ReplicationStatus", "Size"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = local.inventories_bucket_arn
      prefix     = aws_s3_bucket.static.id
      format     = "CSV"
    }
  }
}

resource "aws_s3_bucket" "fallback" {
  provider = aws.eu-west-1

  bucket = "${var.static_bucket_name}-fallback"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "fallback" {
  provider = aws.eu-west-1

  bucket = aws_s3_bucket.fallback.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PublicReadGetObject",
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.fallback.arn}/*"
      }
    ]
  })
}
