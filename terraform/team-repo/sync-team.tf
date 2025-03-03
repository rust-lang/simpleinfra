// CodeBuild project that will run the synchronization, along with the
// CloudWatch log group to store the execution log.

resource "aws_cloudwatch_log_group" "sync_team" {
  name              = "/sync-team"
  retention_in_days = 30
}

resource "aws_codebuild_project" "sync_team" {
  name          = "sync-team"
  description   = "Execution of rust-lang/sync-team with production credentials."
  build_timeout = 30
  service_role  = aws_iam_role.sync_team.arn

  source {
    type      = "NO_SOURCE"
    buildspec = <<-EOF
      ---
      version: 0.2
      phases:
        build:
          commands:
            - sync-team apply
      EOF
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    image                       = module.ecr.url

    environment_variable {
      type  = "PARAMETER_STORE"
      name  = "GITHUB_TOKEN"
      value = "/prod/sync-team/github-token"
    }

    environment_variable {
      type  = "PARAMETER_STORE"
      name  = "MAILGUN_API_TOKEN"
      value = "/prod/sync-team/mailgun-api-token"
    }

    environment_variable {
      type  = "PARAMETER_STORE"
      name  = "EMAIL_ENCRYPTION_KEY"
      value = "/prod/sync-team/email-encryption-key"
    }

    environment_variable {
      type  = "PARAMETER_STORE"
      name  = "ZULIP_USERNAME"
      value = "/prod/sync-team/zulip-username"
    }

    environment_variable {
      type  = "PARAMETER_STORE"
      name  = "ZULIP_API_TOKEN"
      value = "/prod/sync-team/zulip-api-token"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.sync_team.name
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
}

// CloudWatch rule to run the synchronization every day.

resource "aws_cloudwatch_event_rule" "start_daily" {
  name                = "cloudbuild--sync-team"
  description         = "Run the sync-team CodeBuild every day."
  schedule_expression = "cron(0 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "start_daily" {
  rule     = aws_cloudwatch_event_rule.start_daily.name
  arn      = aws_codebuild_project.sync_team.arn
  role_arn = aws_iam_role.start_execution.arn
}

// IAM Role that CodeBuild will assume when running the build. The role will
// grant access to write the logs, read parameters and pull the ECR image.

resource "aws_iam_role" "sync_team" {
  name = "codebuild--sync-team"

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

resource "aws_iam_role_policy_attachment" "sync_team_pull_ecr" {
  role       = aws_iam_role.sync_team.name
  policy_arn = module.ecr.policy_pull_arn
}

resource "aws_iam_role_policy" "sync_team" {
  role = aws_iam_role.sync_team.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowParameterStore"
        Effect = "Allow"
        Action = "ssm:GetParameters"
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/prod/sync-team/*"
        ]
      },
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = "${aws_cloudwatch_log_group.sync_team.arn}:*"
      }
    ]
  })
}

// IAM Role that can be assumed to start the synchronization.

resource "aws_iam_role" "start_execution" {
  name = "start-sync-team"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = [
            "events.amazonaws.com",
            "lambda.amazonaws.com",
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "start_execution" {
  role = aws_iam_role.start_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowStartBuild"
        Effect   = "Allow"
        Action   = "codebuild:StartBuild"
        Resource = aws_codebuild_project.sync_team.arn
      }
    ]
  })
}
