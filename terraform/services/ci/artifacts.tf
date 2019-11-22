resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
  acl    = "public-read"

  dynamic "lifecycle_rule" {
    for_each = toset(["rustc-builds", "rustc-builds-alt"])
    content {
      id      = "cleanup-${lifecycle_rule.value}"
      enabled = true

      prefix = "${lifecycle_rule.value}"

      expiration {
        days = 168
      }

      noncurrent_version_expiration {
        days = 168
      }

      abort_incomplete_multipart_upload_days = 1
    }
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
