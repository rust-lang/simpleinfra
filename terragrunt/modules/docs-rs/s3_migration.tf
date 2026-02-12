// Role assumed by DataSync for reads from the source bucket.
resource "aws_iam_role" "datasync_source_location" {
  count = var.s3_migration_enabled ? 1 : 0

  name = "docs-rs-datasync-source-location"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_source_location_s3" {
  count = var.s3_migration_enabled ? 1 : 0

  role = aws_iam_role.datasync_source_location[0].id
  name = "docs-rs-datasync-source-location-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = "arn:aws:s3:::${var.s3_migration_source_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "arn:aws:s3:::${var.s3_migration_source_bucket_name}/*"
      }
    ]
  })
}

// Role assumed by DataSync for writes into the destination bucket.
resource "aws_iam_role" "datasync_destination_location" {
  count = var.s3_migration_enabled ? 1 : 0

  name = "docs-rs-datasync-destination-location"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_destination_location_s3" {
  count = var.s3_migration_enabled ? 1 : 0

  role = aws_iam_role.datasync_destination_location[0].id
  name = "docs-rs-datasync-destination-location-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = aws_s3_bucket.storage.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Resource = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "datasync_s3_migration" {
  count = var.s3_migration_enabled ? 1 : 0

  name              = "/aws/datasync/docs-rs-storage-import"
  retention_in_days = 30
}

resource "aws_datasync_location_s3" "migration_source" {
  provider = aws.west1
  count    = var.s3_migration_enabled ? 1 : 0

  s3_bucket_arn = "arn:aws:s3:::${var.s3_migration_source_bucket_name}"
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_source_location[0].arn
  }
}

resource "aws_datasync_location_s3" "migration_destination" {
  count = var.s3_migration_enabled ? 1 : 0

  s3_bucket_arn = aws_s3_bucket.storage.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_destination_location[0].arn
  }
}

resource "aws_datasync_task" "migration" {
  count = var.s3_migration_enabled ? 1 : 0

  name                     = "docs-rs-storage-import"
  source_location_arn      = aws_datasync_location_s3.migration_source[0].arn
  destination_location_arn = aws_datasync_location_s3.migration_destination[0].arn
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_s3_migration[0].arn

  options {
    # Unlimited bandwidth to minimize migration time
    bytes_per_second = -1
    log_level        = "BASIC"
    # For one-time imports with TransferMode=ALL, deleted source objects are not removed from destination.
    preserve_deleted_files = "PRESERVE"
    task_queueing          = "ENABLED"
    # Transfers all the content from the source, without comparing to the destination location
    transfer_mode = "ALL"

    # Values I had to set to None to avoid aws errors
    posix_permissions = "NONE"
    uid               = "NONE"
    gid               = "NONE"
  }
}
