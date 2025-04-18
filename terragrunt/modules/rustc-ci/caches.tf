# For the rust-lang repo (prod environment) this was imported.
resource "aws_s3_bucket" "caches" {
  bucket = var.caches_bucket != null ? var.caches_bucket : "${var.repo}-ci-sccache"
}

resource "aws_s3_bucket_lifecycle_configuration" "caches_lifecycle" {
  bucket = aws_s3_bucket.caches.id

  rule {
    status = "Enabled"
    id     = "delete-bucket-after-90-days"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      // This is *in addition* to the delete_caches_after_days above; we
      // don't really need to keep CI caches around in an inaccessible state.
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_policy" "caches" {
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
      },
    ]
  })
}

module "caches_user" {
  source = "../gha-iam-user"

  org  = "rust-lang"
  repo = var.repo

  user_name  = "rustc-ci--rust-lang--caches"
  env_prefix = "CACHES"
}

resource "aws_iam_user_policy" "caches_write" {
  name = "caches-write"
  user = module.caches_user.user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CachesBucketWrite"
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.caches.arn}",
          "${aws_s3_bucket.caches.arn}/*",
        ]
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
      },
      {
        Sid      = "CachesBucketList"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.caches.arn}"
        Action = [
          "s3:ListBucket",
        ],
      },
      {
        Sid      = "HeadBuckets",
        Effect   = "Allow",
        Resource = "*"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
        ],
      },
    ]
  })
}

resource "aws_s3_bucket_acl" "caches" {
  bucket = aws_s3_bucket.caches.id
  acl    = "public-read"
}

# TODO: probably this should be imported
module "caches_cdn" {
  source = "../static-website"

  domain_name        = var.caches_domain != null ? var.caches_domain : "${var.repo}-ci-caches.rust-lang.org"
  origin_domain_name = aws_s3_bucket.caches.bucket_regional_domain_name
  response_policy_id = aws_cloudfront_response_headers_policy.s3.id
}
