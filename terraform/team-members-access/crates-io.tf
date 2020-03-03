// This file defines the permissions of crates.io team members with access to the
// production environment.

resource "aws_iam_group" "crates_io" {
  name = "crates-io"
}

resource "aws_iam_group_policy_attachment" "crates_io_manage_own_credentials" {
  group      = aws_iam_group.crates_io.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "crates_io_enforce_mfa" {
  group      = aws_iam_group.crates_io.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_s3_bucket" "crates_io_buckets" {
  for_each = toset(["crates-io", "staging-crates-io", "rust-temp-cratesio-logs"])
  bucket   = each.value
}

resource "aws_iam_group_policy" "crates_io" {
  group = aws_iam_group.crates_io.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // CloudFront Access
      //
      // The following rules allow crates-io team members to list all
      // CloudFront distributions, see the configuration of the crates.io
      // distributions, and to create invalidations on them.
      {
        Sid    = "CloudFrontListAllDistributions"
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:ListStreamingDistributions",
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudFrontInvalidateCache"
        Effect = "Allow"
        Action = [
          // Allow navigating in the distribution's console
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          // Allow creating invalidations
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudfront:ResourceTag/TeamAccess" = "crates-io"
          }
        }
      },

      // S3 access
      //
      // The following rules allow crates-io team members to list all S3 buckets
      // and to have full access to the crates.io buckets.
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets",
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          // List files in the bucket
          "s3:ListBucket",
          // Interact with the objects
          "s3:AbortMultipartUpload",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = concat(
          [for _, bucket in data.aws_s3_bucket.crates_io_buckets : bucket.arn],
          [for _, bucket in data.aws_s3_bucket.crates_io_buckets : "${bucket.arn}/*"],
        )
      },
    ]
  })
}
