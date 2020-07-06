resource "aws_s3_bucket" "static" {
  bucket = var.bucket
  acl    = "public-read"

  versioning {
    enabled = true
  }

  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
    allowed_headers = ["Authorization"]
  }

  website {
    index_document = "index.html"
    error_document = "doc/nightly/not_found.html"
  }

  // Some files (such as the nightly tarballs) are overridden daily, creating
  // a bunch of old versions nobody cares about. This cleans up those files,
  // while keeping the past 3 months archived in case we need to rollback.
  lifecycle_rule {
    id      = "remove-old-versions"
    enabled = true

    abort_incomplete_multipart_upload_days = 2
    noncurrent_version_expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.static.arn}/*"
    }
  ]
}
EOF
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
      bucket_arn = var.inventories_bucket_arn
      prefix     = aws_s3_bucket.static.id
      format     = "CSV"
    }
  }
}
