module "static_website" {
  source = "../shared/modules/static-website"
  providers = {
    aws = aws.east1
  }
  domain_name        = "perf-data.rust-lang.org"
  origin_domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
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
    id      = "remove-old"
    enabled = true

    abort_incomplete_multipart_upload_days = 2
    noncurrent_version_expiration {
      days = 7
    }
  }
}
