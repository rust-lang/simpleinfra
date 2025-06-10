resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
  acl    = "public-read"

  lifecycle_rule {
    id      = "cleanup-rustc-builds"
    enabled = true

    // Note that this applies equally to rustc-builds and rustc-builds-alt, as
    // it is a prefix.
    prefix = "rustc-builds"

    expiration {
      days = var.delete_artifacts_after_days
    }

    noncurrent_version_expiration {
      // This is *in addition* to the delete_artifacts_after_days above; we
      // don't really need to keep CI artifacts around in an inaccessible state.
      days = 1
    }

    abort_incomplete_multipart_upload_days = 1
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  for_each = toset(var.buckets_public_access ? ["true"] : [])

  bucket = aws_s3_bucket.artifacts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = {
          AWS = "*"
        }
        Sid      = "PublicReadGetObject"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  for_each = toset(var.buckets_public_access ? [] : ["true"])

  bucket = aws_s3_bucket.artifacts.id

  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


module "artifacts_cdn" {
  for_each = toset(var.artifacts_domain == null ? [] : ["true"])

  source = "../../shared/modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = var.artifacts_domain
  origin_domain_name = aws_s3_bucket.artifacts.bucket_regional_domain_name
  response_policy_id = var.response_policy_id
}

data "aws_s3_bucket" "inventories" {
  bucket = "rust-inventories"
}

resource "aws_s3_bucket_inventory" "artifacts" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.artifacts.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "Size", "StorageClass", "IntelligentTieringAccessTier"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = data.aws_s3_bucket.inventories.arn
      prefix     = aws_s3_bucket.artifacts.id
      format     = "CSV"
    }
  }
}
