// Produce releases using the promote-release tool, running on AWS CodeBuild.

data "aws_s3_bucket" "artifacts" {
  bucket = "rust-lang-ci2"
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
            - promote-release /release
      EOF
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    image                       = var.promote_release_ecr_repo.url

    environment_variable {
      name  = "PROMOTE_RELEASE_CLOUDFRONT_DOC_ID"
      value = aws_cloudfront_distribution.doc.id
    }

    environment_variable {
      name  = "PROMOTE_RELEASE_CLOUDFRONT_STATIC_ID"
      value = aws_cloudfront_distribution.static.id
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
        Resource = aws_cloudwatch_log_group.promote_release.arn
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
          "s3:HeadBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "*"
      },

      {
        Sid    = "InvalidateCloudfront"
        Effect = "Allow"
        Action = "cloudfront:CreateInvalidation"
        Resource = [
          aws_cloudfront_distribution.doc.arn,
          aws_cloudfront_distribution.static.arn,
        ]
      },
    ]
  })
}

// Lambda function that will start a build

data "aws_ssm_parameter" "lambda_github_token" {
  name = "/prod/promote-release/lambda-github-token"
}

resource "aws_iam_role" "lambda_promote_release" {
  name = "lambda-promote-release--${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_promote_release" {
  role = aws_iam_role.lambda_promote_release.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadingGitHubToken"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = data.aws_ssm_parameter.lambda_github_token.arn
      },
      {
        Sid      = "AllowDownloadingManifests"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = aws_s3_bucket.static.arn
      },
      {
        Sid      = "AllowStartingReleases"
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.promote_release.arn
      },
      {
        Sid    = "UploadLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

module "lambda_promote_release" {
  source = "../../shared/modules/lambda"

  name       = "promote-release--${var.name}"
  source_dir = "impl/lambdas/promote-release"
  handler    = "lambda_function.handler"
  runtime    = "python3.8"
  role_arn   = aws_iam_role.lambda_promote_release.arn

  timeout_seconds = 30

  environment = {
    "CODEBUILD_PROJECT" = aws_codebuild_project.promote_release.name
    "STATIC_BUCKET"     = aws_s3_bucket.static.bucket
    "STATIC_DIR"        = "dist"
  }
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

  rule = aws_cloudwatch_event_rule.cron_promote_release[each.key].name
  arn  = module.lambda_promote_release.arn

  input = jsonencode({
    channel = each.key
  })
}

resource "aws_lambda_permission" "cron_promote_release" {
  for_each = var.promote_release_cron

  statement_id  = "cron--${var.name}--${each.key}"
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  function_name = module.lambda_promote_release.name
  source_arn    = aws_cloudwatch_event_rule.cron_promote_release[each.key].arn
}
