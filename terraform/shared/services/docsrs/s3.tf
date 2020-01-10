resource "aws_s3_bucket" "storage" {
  bucket = var.storage_bucket
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "backups" {
  bucket = var.backups_bucket
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
