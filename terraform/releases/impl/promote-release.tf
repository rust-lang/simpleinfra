// Produce releases using the promote-release tool, running on AWS CodeBuild.

// Provides extra environment variables to set when running the builder.
variable "extra_environment_variables" {
  type = set(object({
    name  = string
    value = string
    type  = string
  }))
  default = []
}

data "aws_s3_bucket" "artifacts" {
  bucket = "rust-lang-ci2"
}

data "aws_cloudfront_distribution" "doc" {
  id = var.cloudfront_doc_id
}

data "aws_cloudfront_distribution" "static" {
  id = var.cloudfront_static_id
}

resource "aws_cloudwatch_log_group" "promote_release" {
  name              = "/${var.name}/promote-release"
  retention_in_days = 90
}

resource "aws_codebuild_project" "promote_release" {
  name          = "promote-release--${var.name}"
  description   = "Execute the release process in the ${var.name} environment."
  build_timeout = 120
  service_role  = aws_iam_role.promote_release.arn

  source {
    type      = "NO_SOURCE"
    buildspec = <<-EOF
      ---
      version: 0.2
      phases:
        install:
          commands:
            - load-gpg-keys
        build:
          commands:
            - promote-release $CODEBUILD_SRC_DIR/release
      EOF
  }

  environment {
    compute_type                = "BUILD_GENERAL1_2XLARGE"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    image                       = var.promote_release_ecr_repo.url

    environment_variable {
      name  = "PROMOTE_RELEASE_CLOUDFRONT_DOC_ID"
      value = data.aws_cloudfront_distribution.doc.id
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_CLOUDFRONT_STATIC_ID"
      value = data.aws_cloudfront_distribution.static.id
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_DOWNLOAD_BUCKET"
      value = data.aws_s3_bucket.artifacts.id
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_DOWNLOAD_DIR"
      value = "rustc-builds"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_GPG_KEY_FILE"
      value = "/tmp/gnupg/keys/secret.asc"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_GPG_PASSWORD_FILE"
      value = "/tmp/gnupg/key-password"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_UPLOAD_ADDR"
      value = "https://${var.static_domain_name}"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_UPLOAD_BUCKET"
      value = var.bucket
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_UPLOAD_DIR"
      value = "dist"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_GITHUB_APP_ID"
      value = "217112"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_GITHUB_APP_KEY"
      value = data.aws_ssm_parameter.github_app_key.name
      type  = "PARAMETER_STORE"
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_RECOMPRESS_XZ"
      value = "1"
    }

    dynamic "environment_variable" {
      for_each = var.extra_environment_variables
      content {
        name  = environment_variable.value["name"]
        value = environment_variable.value["value"]
        type  = environment_variable.value["type"]
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.promote_release.name
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

// IAM Role that CloudBuild will assume when running the release. The role can
// write logs, pull the ECR image, interact with the assigned buckets and
// invalidate the CloudFront distributions.

resource "aws_iam_role" "promote_release" {
  name = "codebuild--promote-release--${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

output "codebuild_role_name" {
  value = aws_iam_role.promote_release.name
}

resource "aws_iam_role_policy_attachment" "promote_release_pull_ecr" {
  role       = aws_iam_role.promote_release.name
  policy_arn = var.promote_release_ecr_repo.policy_pull_arn
}

resource "aws_iam_role_policy" "promote_release" {
  role = aws_iam_role.promote_release.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = "${aws_cloudwatch_log_group.promote_release.arn}:*"
      },
      {
        Sid    = "BucketsReadWrite"
        Effect = "Allow"
        Action = [
          "s3:PutObjectAcl",
          "s3:PutObject",
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = [
          // Uploads bucket
          "${aws_s3_bucket.static.arn}/doc",
          "${aws_s3_bucket.static.arn}/doc/*",
          "${aws_s3_bucket.static.arn}/dist",
          "${aws_s3_bucket.static.arn}/dist/*",
        ]
      },
      {
        Sid    = "BucketsReadDelete"
        Effect = "Allow"
        Action = [
          "s3:GetObjectAcl",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = [
          // Artifacts bucket
          "${data.aws_s3_bucket.artifacts.arn}/rustc-builds",
          "${data.aws_s3_bucket.artifacts.arn}/rustc-builds/*",
        ]
      },
      {
        Sid    = "BucketsReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAcl",
        ]
        Resource = "${var.release_keys_bucket_arn}/*",
      },
      {
        Sid    = "BucketsList"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = [
          aws_s3_bucket.static.arn,
          data.aws_s3_bucket.artifacts.arn,
          var.release_keys_bucket_arn,
        ]
      },
      {
        Sid    = "HeadBuckets"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
        ]
        Resource = "*"
      },
      {
        Sid    = "InvalidateCloudfront"
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        Resource = [
          data.aws_cloudfront_distribution.doc.arn,
          data.aws_cloudfront_distribution.static.arn,
        ]
      },
      {
        Sid    = "AllowParameters"
        Effect = "Allow"
        Action = ["ssm:GetParameters"]
        Resource = [
          "${data.aws_ssm_parameter.github_app_key.arn}",
          "${data.aws_ssm_parameter.internals_discourse.arn}",
          "${data.aws_ssm_parameter.users_discourse.arn}",
        ]
      }
    ]
  })
}

data "aws_ssm_parameter" "github_app_key" {
  name            = "/prod/promote-release/github-app-key"
  with_decryption = false
}

data "aws_ssm_parameter" "internals_discourse" {
  name            = "/prod/promote-release/discourse-api-key"
  with_decryption = false
}

data "aws_ssm_parameter" "users_discourse" {
  name            = "/prod/promote-release/users-discourse-api-key"
  with_decryption = false
}

// CloudWatch Rule that will execute the release process periodically.

resource "aws_cloudwatch_event_rule" "cron_promote_release" {
  for_each = var.promote_release_cron

  name                = "promote-release--${var.name}--${each.key}"
  description         = "Periodically promote channel ${each.key} in the ${var.name} environment"
  schedule_expression = each.value
}

resource "aws_cloudwatch_event_target" "cron_promote_release" {
  for_each = var.promote_release_cron

  rule     = aws_cloudwatch_event_rule.cron_promote_release[each.key].name
  arn      = aws_codebuild_project.promote_release.arn
  role_arn = aws_iam_role.start_promote_release.arn

  input = jsonencode({
    environmentVariablesOverride = [
      {
        name  = "PROMOTE_RELEASE_CHANNEL"
        value = each.key
        type  = "PLAINTEXT"
      }
    ]
  })
}

resource "aws_iam_role" "start_promote_release" {
  name = "start-promote-release--${var.name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "start_promote_release" {
  role = aws_iam_role.start_promote_release.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowStartBuild"
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.promote_release.arn
      }
    ]
  })
}
