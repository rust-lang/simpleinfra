resource "aws_s3_bucket" "static" {
  bucket = var.static_bucket_name
  versioning {
    enabled = true
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
