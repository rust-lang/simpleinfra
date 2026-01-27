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
        Sid    = "S3Permissions"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:ResourceTag/TeamAccess" = "content"
          }
        }
      },
      {
        Sid    = "CloudFrontListDistributions"
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:ListStreamingDistributions"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudFrontPermissions"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetCachePolicy",
          "cloudfront:GetCachePolicyConfig",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudfront:ResourceTag/TeamAccess" = "content"
          }
        }
      }
    ]
  })
}
