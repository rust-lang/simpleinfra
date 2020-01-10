locals {
  static_directories = ["doc", "dist"]
  static_buckets     = [var.static_bucket_arn, var.dev_static_bucket_arn]
  ci_directories     = ["rustc-builds", "rustc-builds-alt"]
  ci_buckets         = [var.ci_bucket_arn]
}

data "aws_iam_policy_document" "promote_release" {
  version = "2012-10-17"

  statement {
    sid    = "StaticBucketsWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]
    resources = flatten([
      for bucket in local.static_buckets : [
        for directory in local.static_directories : [
          "${bucket}/${directory}",
          "${bucket}/${directory}/*",
        ]
      ]
    ])
  }

  statement {
    sid    = "CiBucketsWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]
    resources = flatten([
      for bucket in local.ci_buckets : [
        for directory in local.ci_directories : [
          "${bucket}/${directory}",
          "${bucket}/${directory}/*",
        ]
      ]
    ])
  }

  statement {
    sid    = "BucketsList"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]
    resources = concat(local.static_buckets, local.ci_buckets)
  }

  statement {
    sid    = "HeadBuckets"
    effect = "Allow"

    actions = [
      "s3:HeadBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "InvalidateCloudfront"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "promote_release" {
  name        = "promote-release"
  description = "Permissions needed to release Rust"
  policy      = data.aws_iam_policy_document.promote_release.json
}
