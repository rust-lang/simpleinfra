locals {
  rustc_builds     = "rustc-builds"
  rustc_builds_alt = "rustc-builds-alt"
  iam_prefix       = "rustc-ci--rust-lang--${var.repo}"

  s3_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ArtifactsBucketWrite"
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/${local.rustc_builds}",
          "${aws_s3_bucket.artifacts.arn}/${local.rustc_builds}/*",
          "${aws_s3_bucket.artifacts.arn}/${local.rustc_builds_alt}",
          "${aws_s3_bucket.artifacts.arn}/${local.rustc_builds_alt}/*",
        ]
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
      },
      {
        Sid      = "ArtifactsBucketList"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.artifacts.arn}"
        Action = [
          "s3:ListBucket",
        ],
      },
      {
        Sid      = "HeadBuckets",
        Effect   = "Allow",
        Resource = "*"
        Action = [
          "s3:HeadBucket",
          "s3:GetBucketLocation",
        ],
      },
    ]
  })
}

# For rust-lang this was imported.
resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket != null ? var.artifacts_bucket : "rust-lang-ci2"
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts_lifecycle" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    status = "Enabled"
    id     = "cleanup-${local.rustc_builds}"

    // Note that this applies equally to rustc-builds and rustc-builds-alt, as
    // it is a prefix.
    filter {
      prefix = local.rustc_builds
    }

    expiration {
      days = 168
    }

    noncurrent_version_expiration {
      // This is *in addition* to the delete_artifacts_after_days above; we
      // don't really need to keep CI artifacts around in an inaccessible state.
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Principal = {
          AWS = "*"
        }
        Sid      = "PublicReadGetObject"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
    ]
  })
}

module "artifacts_user" {
  source = "../gha-iam-user"

  org  = "rust-lang"
  repo = var.repo

  user_name  = "${local.iam_prefix}--artifacts"
  env_prefix = "ARTIFACTS"
}

resource "aws_iam_user_policy" "artifacts_write" {
  name = "artifacts-write"
  user = module.artifacts_user.user_name

  policy = local.s3_policy
}

resource "aws_s3_bucket_acl" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  acl    = "public-read"
}

# TODO: probably this should be imported
module "artifacts_cdn" {
  source = "../static-website"

  domain_name        = "ci-artifacts.rust-lang.org"
  origin_domain_name = aws_s3_bucket.artifacts.bucket_regional_domain_name
  response_policy_id = data.terraform_remote_state.shared.outputs.mdbook_response_policy
}

data "aws_s3_bucket" "inventories" {
  bucket = "rust-inventories"
}

resource "aws_s3_bucket_inventory" "artifacts" {
  name    = "all-objects-csv"
  bucket  = aws_s3_bucket.artifacts.id
  enabled = true

  included_object_versions = "Current"
  optional_fields          = ["ETag", "Size", "StorageClass", "IntelligentTieringAccessTier"]

  schedule {
    frequency = "Weekly"
  }
  destination {
    bucket {
      bucket_arn = data.aws_s3_bucket.inventories.arn
      prefix     = aws_s3_bucket.artifacts.id
      format     = "CSV"
    }
  }
}

resource "aws_iam_role" "try_builds" {
  name = "${local.iam_prefix}--try-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "arn:aws:iam::890664054962:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:rust-lang/${var.repo}:ref:refs/heads/automation/bors/try"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "try_builds" {
  name   = "put-objects"
  role   = aws_iam_role.try_builds.id
  policy = local.s3_policy
}
