resource "aws_s3_bucket" "static" {
  bucket = var.static_bucket_name

  versioning {
    enabled = true
  }

  // Keep only the live db-dump.tar.gz and the previous day's version, removing
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
