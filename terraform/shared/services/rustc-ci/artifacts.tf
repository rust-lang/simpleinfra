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
  bucket = aws_s3_bucket.artifacts.id

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
      "Resource": "${aws_s3_bucket.artifacts.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "artifacts" {
  name = "${var.iam_prefix}--artifacts"
}

resource "aws_iam_access_key" "artifacts" {
  user = aws_iam_user.artifacts.name
}

resource "aws_iam_policy" "artifacts_write" {
  name        = "${var.iam_prefix}--artifacts-write"
  description = "Write access to the ${aws_s3_bucket.artifacts.id} S3 bucket"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ArtifactsBucketWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.artifacts.arn}/rustc-builds",
        "${aws_s3_bucket.artifacts.arn}/rustc-builds/*",
        "${aws_s3_bucket.artifacts.arn}/rustc-builds-alt",
        "${aws_s3_bucket.artifacts.arn}/rustc-builds-alt/*"
      ]
    },
    {
      "Sid": "ArtifactsBucketList",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.artifacts.arn}"
      ]
    },
    {
      "Sid": "HeadBuckets",
      "Effect": "Allow",
      "Action": [
        "s3:HeadBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "artifacts_write" {
  user       = aws_iam_user.artifacts.name
  policy_arn = aws_iam_policy.artifacts_write.arn
}

module "static_website_ci_artifacts" {
  source = "../../modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = var.artifacts_domain
  origin_domain_name = aws_s3_bucket.artifacts.bucket_regional_domain_name
}
