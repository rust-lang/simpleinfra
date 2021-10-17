resource "aws_s3_bucket" "caches" {
  bucket = var.caches_bucket
  acl    = var.buckets_public_access ? "public-read" : "private"

  lifecycle_rule {
    id      = "delete-bucket-after-90-days"
    enabled = true

    expiration {
      days = var.delete_caches_after_days
    }

    noncurrent_version_expiration {
      // This is *in addition* to the delete_caches_after_days above; we don't
      // really need to keep CI caches around in an inaccessible state.
      days = 1
    }

    abort_incomplete_multipart_upload_days = 1
  }
}

resource "aws_s3_bucket_policy" "caches" {
  for_each = toset(var.buckets_public_access ? ["true"] : [])

  bucket = aws_s3_bucket.caches.id
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
        Resource = "${aws_s3_bucket.caches.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "caches" {
  for_each = toset(var.buckets_public_access ? [] : ["true"])

  bucket = aws_s3_bucket.caches.id

  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_user" "caches" {
  name = "${var.iam_prefix}--caches"
}

resource "aws_iam_access_key" "caches_legacy" {
  user = aws_iam_user.caches.name
}

resource "aws_iam_user_policy" "caches_write" {
  name = "caches-write"
  user = aws_iam_user.caches.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CachesBucketWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = [
          "${aws_s3_bucket.caches.arn}",
          "${aws_s3_bucket.caches.arn}/*",
        ]
      },
      {
        Sid    = "CachesBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "${aws_s3_bucket.caches.arn}"
      },
      {
        Sid    = "HeadBuckets"
        Effect = "Allow"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "*"
      },
    ]
  })
}

module "caches_cdn" {
  for_each = toset(var.caches_domain == null ? [] : ["true"])

  source = "../../shared/modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = var.caches_domain
  origin_domain_name = aws_s3_bucket.caches.bucket_regional_domain_name
}
