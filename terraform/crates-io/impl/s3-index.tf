resource "aws_s3_bucket" "index" {
  bucket = var.index_bucket_name

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "index" {
  bucket = aws_s3_bucket.index.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontAccess",
        Effect = "Allow"
        Principal = {
          AWS = "${aws_cloudfront_origin_access_identity.index.iam_arn}"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.index.arn}",
          "${aws_s3_bucket.index.arn}/*"
        ]
      }
    ]
  })
}

// We provide public access only through CloudFront, which is enabled with a
// CloudFront origin access identity.
resource "aws_s3_bucket_public_access_block" "index" {
  bucket = aws_s3_bucket.index.id

  restrict_public_buckets = true
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
}

resource "aws_s3_bucket_inventory" "index" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.index.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "ReplicationStatus", "Size"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = var.inventories_bucket_arn
      prefix     = aws_s3_bucket.index.id
      format     = "CSV"
    }
  }
}
