resource "aws_s3_bucket" "static" {
  bucket = var.bucket
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "static" {
  bucket = aws_s3_bucket.static.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "static" {
  bucket = aws_s3_bucket.static.id
  cors_rule {
    allowed_origins = ["*"]
    allowed_methods = ["GET"]
    max_age_seconds = 3000
    allowed_headers = ["Authorization"]
  }
}


resource "aws_s3_bucket_website_configuration" "static" {
  bucket = aws_s3_bucket.static.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "doc/nightly/not_found.html"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  // Some files (such as the nightly tarballs) are overridden daily, creating
  // a bunch of old versions nobody cares about. This cleans up those files,
  // while keeping the past 3 months archived in case we need to rollback.
  rule {
    id     = "remove-old-versions"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 2
    }
    noncurrent_version_expiration {
      noncurrent_days = 90
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
  optional_fields = [
    "ETag", "ReplicationStatus", "Size", "IntelligentTieringAccessTier",
    "StorageClass",
  ]

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
