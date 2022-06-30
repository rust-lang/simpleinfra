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
  for_each = toset(["crates-io", "staging-crates-io"])
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
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:ListStreamingDistributions",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          // Allow navigating in the distribution':"s console
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
        Effect = "Allow"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [for _, bucket in data.aws_s3_bucket.crates_io_buckets : bucket.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListObjectsV2",
        ]
        Resource = [for _, bucket in data.aws_s3_bucket.crates_io_buckets : "${bucket.arn}/*"]
      },

      // Support access
      //
      // The following rules allow crates-io team members to reach out to AWS
      // Support without involving someone from the infrastructure team.
      {
        Sid      = "SupportAccess"
        Effect   = "Allow"
        Action   = ["support:*"]
        Resource = "*"
      },
    ]
  })
}
