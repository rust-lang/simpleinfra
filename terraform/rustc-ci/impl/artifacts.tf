resource "aws_s3_bucket" "artifacts" {
  bucket = var.artifacts_bucket
  acl    = "public-read"

  lifecycle_rule {
    id      = "cleanup-rustc-builds"
    enabled = true

    // Note that this applies equally to rustc-builds and rustc-builds-alt, as
    // it is a prefix.
    prefix = "rustc-builds"

    expiration {
      days = var.delete_artifacts_after_days
    }

    noncurrent_version_expiration {
      // This is *in addition* to the delete_artifacts_after_days above; we
      // don't really need to keep CI artifacts around in an inaccessible state.
      days = 1
    }

    abort_incomplete_multipart_upload_days = 1
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  for_each = toset(var.buckets_public_access ? ["true"] : [])

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

resource "aws_s3_bucket_public_access_block" "artifacts" {
  for_each = toset(var.buckets_public_access ? [] : ["true"])

  bucket = aws_s3_bucket.artifacts.id

  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "artifacts_user" {
  source = "../../shared/modules/gha-iam-user"

  org  = split("/", var.repo)[0]
  repo = split("/", var.repo)[1]

  user_name  = "${var.iam_prefix}--artifacts"
  env_prefix = "ARTIFACTS"
}

resource "aws_iam_access_key" "artifacts_legacy" {
  user = module.artifacts_user.user_name
}

resource "aws_iam_user_policy" "artifacts_write" {
  name = "artifacts-write"
  user = module.artifacts_user.user_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ArtifactsBucketWrite"
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/rustc-builds",
          "${aws_s3_bucket.artifacts.arn}/rustc-builds/*",
          "${aws_s3_bucket.artifacts.arn}/rustc-builds-alt",
          "${aws_s3_bucket.artifacts.arn}/rustc-builds-alt/*",
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

module "artifacts_cdn" {
  for_each = toset(var.artifacts_domain == null ? [] : ["true"])

  source = "../../shared/modules/static-website"
  providers = {
    aws = aws.east1
  }

  domain_name        = var.artifacts_domain
  origin_domain_name = aws_s3_bucket.artifacts.bucket_regional_domain_name
  response_policy_id = var.response_policy_id
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

data "aws_iam_openid_connect_provider" "gha" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "oidc" {
  name = "${var.iam_prefix}--role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = "${aws_cognito_identity_pool.main.id}"
            // This forces the caller to set the session name according to the caller's run & sha
            "sts:RoleSessionName"       = "$${aws:RequestTag/run_id}@$${aws:RequestTag/sha}"
            "aws:RequestTag/repository" = "${var.source_repo}"
            // For now only allow new bors & try builds
            "aws:RequestTag/ref"        = "refs/heads/automation/bors/try"
            "aws:RequestTag/event_name" = "push"
          }
        }
      },
      {
        Effect = "Allow"
        Action = "sts:TagSession"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = "${aws_cognito_identity_pool.main.id}"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "put-objects"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "ArtifactsBucketWrite"
          Effect = "Allow"
          Resource = [
            "${aws_s3_bucket.artifacts.arn}/rustc-builds/$${aws:PrincipalTag/sha}/*",
            "${aws_s3_bucket.artifacts.arn}/rustc-builds-alt/$${aws:PrincipalTag/sha}/*",
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
}
