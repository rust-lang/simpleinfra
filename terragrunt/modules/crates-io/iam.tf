// This file configures the IAM users, policies and roles for crates.io

resource "aws_iam_user" "heroku" {
  name = "${var.iam_prefix}--heroku"
}

resource "aws_iam_user_policy" "heroku" {
  name = "inline"
  user = aws_iam_user.heroku.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        Resource = [
          aws_cloudfront_distribution.index.arn,
          aws_cloudfront_distribution.static.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "static_write" {
  name        = "${var.iam_prefix}--static-write"
  description = "Write access to the ${var.static_bucket_name} S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StaticBucketWrite"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
        ]
        Resource = [
          "${aws_s3_bucket.static.arn}/*",
          "${aws_s3_bucket.index.arn}/*",
        ]
      },
      {
        Sid      = "StaticBucketList"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [aws_s3_bucket.static.arn, aws_s3_bucket.index.arn]
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

resource "aws_iam_user_policy_attachment" "heroku_static_write" {
  user       = aws_iam_user.heroku.name
  policy_arn = aws_iam_policy.static_write.arn
}

resource "aws_iam_policy" "cdn_logs_read" {
  name        = "${var.iam_prefix}--cdn-logs-read"
  description = "Read access to the S3 bucket with CDN logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CDNLogsRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "${aws_s3_bucket.logs.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "heroku_cdn_logs_read" {
  user       = aws_iam_user.heroku.name
  policy_arn = aws_iam_policy.cdn_logs_read.arn
}

resource "aws_iam_role" "s3_replication" {
  name = "${var.iam_prefix}--s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = aws_s3_bucket.static.arn
          }
        }
      }
    ]
  })

  inline_policy {
    name = "replication"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
          ]
          Resource = "${aws_s3_bucket.static.arn}/*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags",
          ]
          Resource = "${aws_s3_bucket.fallback.arn}/*"
        },
      ]
    })
  }
}
