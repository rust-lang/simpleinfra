resource "aws_ssoadmin_permission_set" "content_s3_write" {
  instance_arn = local.instance_arn
  name         = "ContentS3Write"
}

resource "aws_ssoadmin_permission_set_inline_policy" "content_s3_write" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.content_s3_write.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::rust-content-internal",
          "arn:aws:s3:::rust-content-public"
        ]
      },
      {
        Sid    = "ReadWriteObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::rust-content-internal/*",
          "arn:aws:s3:::rust-content-public/*"
        ]
      }
    ]
  })
}
