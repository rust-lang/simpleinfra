resource "aws_s3_bucket" "logs" {
  bucket = "rust-${replace(var.webapp_domain_name, ".", "-")}-logs"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

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

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "cdn_log_event_queue" {
  bucket = aws_s3_bucket.logs.id

  queue {
    id            = "cloudfront"
    events        = ["s3:ObjectCreated:*"]
    queue_arn     = var.cdn_log_event_queue_arn
    filter_prefix = "cloudfront/"
  }

  queue {
    id            = "fastly"
    events        = ["s3:ObjectCreated:*"]
    queue_arn     = var.cdn_log_event_queue_arn
    filter_prefix = "fastly-requests/"
  }
}
