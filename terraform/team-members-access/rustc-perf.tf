// This file defines the permissions of rustc-perf team members with access to the
// production environment.

resource "aws_iam_group" "rustc_perf" {
  name = "rustc-perf"
}

resource "aws_iam_group_policy_attachment" "rustc_perf_manage_own_credentials" {
  group      = aws_iam_group.rustc_perf.name
  policy_arn = aws_iam_policy.manage_own_credentials.arn
}

resource "aws_iam_group_policy_attachment" "rustc_perf_enforce_mfa" {
  group      = aws_iam_group.rustc_perf.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

data "aws_ssm_parameter" "rustc_perf_credentials" {
  name            = "/prod/rds/shared/connection-urls/rustc_perf"
  with_decryption = false
}

data "aws_cloudwatch_log_group" "rustc_perf_web" {
  name = "/ecs/rustc-perf"
}

resource "aws_iam_group_policy" "rustc_perf" {
  group = aws_iam_group.rustc_perf.name
  name  = "prod-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowRDSCredentialsAccess"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = data.aws_ssm_parameter.rustc_perf_credentials.arn
      },
      {
        Sid    = "AllowLogs"
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = [
          "arn:aws:logs:${data.aws_arn.logs.region}:${data.aws_arn.logs.account}:log-group:*",
          "${data.aws_cloudwatch_log_group.rustc_perf_web.arn}:*",
          "${data.aws_cloudwatch_log_group.rustc_perf_web.arn}:*:log-stream:*",
        ]
      },
    ]
  })
}

data "aws_arn" "logs" {
  arn = data.aws_cloudwatch_log_group.rustc_perf_web.arn
}
