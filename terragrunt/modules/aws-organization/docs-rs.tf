resource "aws_ssoadmin_permission_set" "docs_rs_s3_write" {
  instance_arn = local.instance_arn
  name         = "DocsRsS3Write"
}

resource "aws_ssoadmin_permission_set_inline_policy" "docs_rs_s3_write" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.docs_rs_s3_write.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ListDocsRsBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "arn:aws:s3:::docs-rs-storage-*"
      },
      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAttributes",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:DeleteObjectTagging",
        ]
        Resource = "arn:aws:s3:::docs-rs-storage-*/*"
      },
    ]
  })
}
