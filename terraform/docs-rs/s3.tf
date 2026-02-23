resource "aws_s3_bucket" "storage" {
  bucket = "rust-docs-rs"
}

# Versioning is required for S3 CRR.
resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_inventory" "storage" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.storage.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "ReplicationStatus", "Size"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = data.terraform_remote_state.shared.outputs.inventories_bucket_arn
      prefix     = aws_s3_bucket.storage.id
      format     = "CSV"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "backups" {
  bucket = "docs.rs-backups"
  acl    = "private"

  lifecycle_rule {
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    id                                     = "Expire database/ backups after 30 days"
    prefix                                 = "database/"

    expiration {
      days                         = 30
      expired_object_delete_marker = false
    }

    noncurrent_version_expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// Allow principals in docs-rs-prod account to read this bucket for DataSync.
resource "aws_s3_bucket_policy" "storage_datasync_cross_account_read" {
  bucket = aws_s3_bucket.storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDataSyncSourceRoleReadBucket"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::760062276060:root"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = aws_s3_bucket.storage.arn
      },
      {
        Sid    = "AllowDataSyncSourceRoleReadObjects"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::760062276060:root"
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })
}
