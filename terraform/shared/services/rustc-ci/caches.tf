resource "aws_s3_bucket" "caches" {
  bucket = var.caches_bucket
  acl    = "public-read"

  lifecycle_rule {
    id      = "delete-bucket-after-90-days"
    enabled = true

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      days = 90
    }

    abort_incomplete_multipart_upload_days = 1
  }
}

resource "aws_s3_bucket_policy" "caches" {
  bucket = aws_s3_bucket.caches.id

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
      "Resource": "${aws_s3_bucket.caches.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_user" "caches" {
  name = "${var.iam_prefix}--caches"
}

resource "aws_iam_access_key" "caches" {
  user = aws_iam_user.caches.name
}

resource "aws_iam_policy" "caches_write" {
  name        = "${var.iam_prefix}--caches-write"
  description = "Write access to the ${aws_s3_bucket.caches.id} S3 bucket"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CachesBucketWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "${aws_s3_bucket.caches.arn}",
        "${aws_s3_bucket.caches.arn}/*"
      ]
    },
    {
      "Sid": "CachesBucketList",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.caches.arn}"
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

resource "aws_iam_user_policy_attachment" "caches_write" {
  user       = aws_iam_user.caches.name
  policy_arn = aws_iam_policy.caches_write.arn
}
