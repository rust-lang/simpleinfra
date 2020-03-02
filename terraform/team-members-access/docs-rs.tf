// This file defines the permissions of docs.rs team members with access to the
// production environment.

resource "aws_iam_group" "docs_rs" {
  name = "docs-rs"
}

resource "aws_iam_group_policy_attachment" "docs_rs_manage_own_credentials" {
  group      = aws_iam_group.docs_rs.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "docs_rs_enforce_mfa" {
  group      = aws_iam_group.docs_rs.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_s3_bucket" "docs_rs_buckets" {
  for_each = toset(["rust-docs-rs", "docs.rs-backups"])
  bucket   = each.value
}

resource "aws_iam_group_policy" "docs_rs" {
  group = aws_iam_group.docs_rs.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // CloudFront Access
      //
      // The following rules allow docs-rs team members to list
      // all CloudFront distributions, see the configuration of the docs.rs
      // distribution, and to create invalidations on it.
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
            "cloudfront:ResourceTag/TeamAccess" = "docs-rs"
          }
        }
      },

      // EC2 access
      //
      // The following rules allow docs-rs team members to list all EC2
      // instances, and to start/stop/reboot the docs.rs instance.
      {
        Sid    = "EC2ListAllInstances",
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2PowerOnOff"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/TeamAccess" = "docs-rs"
          }
        }
      },

      // S3 access
      //
      // The following rules allow docs-rs team members to list all S3 buckets
      // and to have full access to the docs.rs buckets.
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
          [for _, bucket in data.aws_s3_bucket.docs_rs_buckets : bucket.arn],
          [for _, bucket in data.aws_s3_bucket.docs_rs_buckets : "${bucket.arn}/*"],
        )
      },
    ]
  })
}
