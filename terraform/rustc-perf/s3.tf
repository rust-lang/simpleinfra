module "static_website" {
  source = "../shared/modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name            = "perf-data.rust-lang.org"
  origin_domain_name     = aws_s3_bucket.bucket.bucket_regional_domain_name
  origin_access_identity = aws_cloudfront_origin_access_identity.bucket.cloudfront_access_identity_path
}

resource "aws_iam_user" "s3" {
  name = "s3--rust-lang--rustc-perf"
}

resource "aws_iam_access_key" "s3" {
  user = aws_iam_user.s3.name
}

resource "aws_ssm_parameter" "s3_access_key" {
  name  = "/iam-users/${aws_iam_access_key.s3.user}/access-keys/${aws_iam_access_key.s3.id}"
  value = aws_iam_access_key.s3.secret

  type = "SecureString"
}

resource "aws_iam_policy" "upload" {
  name        = "s3-upload-rustc-perf"
  description = "Allow to upload new archives into rustc-perf s3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUpload",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "s3_upload" {
  user       = aws_iam_user.s3.name
  policy_arn = aws_iam_policy.upload.arn
}

resource "aws_s3_bucket" "bucket" {
  bucket = "rustc-perf"
  acl    = "public-read"

  versioning {
    enabled = true
  }

  // We keep some level of backup, but not too much -- the primary data store
  // is the postgres db, and that's already backed up.
  lifecycle_rule {
    id      = "delete old dbs"
    prefix  = "export.db.sz"
    enabled = true

    abort_incomplete_multipart_upload_days = 2
    noncurrent_version_expiration {
      days = 7
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowCloudfront"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.bucket.iam_arn
        }
      },
      {
        Sid      = "DenyCloudfront"
        Effect   = "Deny"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/db-exports/*"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.bucket.iam_arn
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "bucket" {
  comment = "perf-data.rust-lang.org"
}
