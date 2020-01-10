// This file configures the IAM users, policies and roles for crates.io

resource "aws_iam_user" "heroku" {
  name = "${var.iam_prefix}--heroku"
}

resource "aws_iam_access_key" "heroku" {
  user = aws_iam_user.heroku.name
}

resource "aws_iam_policy" "static_write" {
  name        = "${var.iam_prefix}--static-write"
  description = "Write access to the ${var.static_bucket_name} S3 bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StaticBucketWrite",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.static.arn}/*"
      ]
    },
    {
      "Sid": "StaticBucketList",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "${aws_s3_bucket.static.arn}"
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

resource "aws_iam_user_policy_attachment" "heroku_static_write" {
  user       = aws_iam_user.heroku.name
  policy_arn = aws_iam_policy.static_write.arn
}
