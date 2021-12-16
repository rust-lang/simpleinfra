// Configuration of our S3 buckets

resource "aws_s3_bucket" "rust_inventories" {
  bucket = "rust-inventories"
  acl    = "private"

  lifecycle_rule {
    id      = "clean inventories"
    enabled = true

    abort_incomplete_multipart_upload_days = 7
    expiration {
      days = 7
    }
    noncurrent_version_expiration {
      days = 7
    }
  }
}

resource "aws_s3_bucket_policy" "rust_inventories" {
  bucket = aws_s3_bucket.rust_inventories.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowInventoryGeneration",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.rust_inventories.arn}/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "ArnLike": {
          "aws:SourceArn": [
            "arn:aws:s3:::static-rust-lang-org",
            "arn:aws:s3:::crates-io",
            "${module.service_cratesio_staging.static_bucket_arn}",
            "${aws_s3_bucket.rust_lang_ci_mirrors.arn}",
            "arn:aws:s3:::rust-docs-rs",
            "arn:aws:s3:::rust-lang-ci2"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "rust_inventories" {
  bucket = aws_s3_bucket.rust_inventories.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "rust_lang_ci_mirrors" {
  bucket = "rust-lang-ci-mirrors"
  acl    = "public-read"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_inventory" "rust_lang_ci_mirrors" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.rust_lang_ci_mirrors.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "ReplicationStatus", "Size"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = aws_s3_bucket.rust_inventories.arn
      prefix     = aws_s3_bucket.rust_lang_ci_mirrors.id
      format     = "CSV"
    }
  }
}

resource "aws_s3_bucket" "rust_lang_crates_io_index" {
  bucket = "tmp-cratesio-index"
  acl    = "private"
}
