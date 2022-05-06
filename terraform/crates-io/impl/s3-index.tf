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
        Sid    = "PublicReadGetObject",
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.index.arn}/*"
      }
    ]
  })
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
