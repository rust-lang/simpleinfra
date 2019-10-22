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

resource "aws_s3_bucket" "rust_lang_ci_mirrors" {
  bucket = "rust-lang-ci-mirrors"
  acl    = "public"

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
